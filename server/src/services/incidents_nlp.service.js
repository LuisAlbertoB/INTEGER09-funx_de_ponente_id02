/**
 * Servicio NLP para el Centro de Incidencias Inteligente.
 * Enfoque híbrido: keywords determinísticos primero, Naive Bayes como fallback.
 * AI-ready: reemplaza analizar() y buscarSimilares() para conectar OpenAI/Gemini.
 */

const natural = require('natural');
const tokenizer = new natural.WordTokenizer();

// ─── Normalización y tokenización ────────────────────────────────────────────

const STOPWORDS = new Set([
  'el','la','los','las','de','del','en','un','una','es','no','se','con','y',
  'a','que','al','su','por','para','hay','esta','estan','est','muy','mas',
  'si','o','pero','como','ya','todo','cuando','tambien','me','te','le','nos',
  'les','este','estos','estas','mi','tu','nuestro','fue','ser','tener','hacer',
  'poder','deber','querer','tiene','tienen','tengo','ahi','aqui','lo','ese',
  'eso','esa','han','haber','he','ha','son','somos','soy',
]);

function normalize(text) {
  return text.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
}

function tokenize(text) {
  const words = tokenizer.tokenize(normalize(text)) || [];
  return words.filter((w) => w.length >= 2 && !STOPWORDS.has(w));
}

// ─── Prioridad por categoría ──────────────────────────────────────────────────

const PRIORITY_BY_CATEGORY = {
  security: 'critical',
  electrical: 'critical',
  audio: 'high',
  video: 'high',
  internet: 'high',
  registration: 'medium',
  access: 'medium',
  logistics: 'medium',
  climatization: 'low',
  cleaning: 'low',
  infrastructure: 'low',
  other: 'low',
};

// ─── Mapa de palabras clave por categoría ────────────────────────────────────
// Estas son la primera línea de defensa: si hay match → categoría segura.
// Cuantos más matches en una categoría, más confianza.

const KEYWORD_MAP = {
  audio: [
    'bocina','bocinas','altavoz','altavoces','bafle','bafles','parlante',
    'microfono','micro','audio','sonido','volumen','acustica','escuchar',
    'oye','oirse','escucha','ruido','silencio','amplificador','speaker',
  ],
  video: [
    'proyector','pantalla','canon','imagen','display','hdmi','vga',
    'television','tv','monitor','beamer','diapositiva','presentacion',
    'visualizar','ver','video','proyeccion','resolution','pixeles',
  ],
  internet: [
    'internet','wifi','red','conexion','senal','router','conectar',
    'conectividad','banda','ancha','latencia','descarga','navegacion',
    'ip','ethernet','cable','modem','hub','switch','desconectado',
  ],
  electrical: [
    'luz','electricidad','corriente','enchufe','foco','voltaje',
    'tomacorriente','energia','planta','apagon','interruptor','cable',
    'corto','fuente','bateria','ups','generador','alimentacion',
  ],
  registration: [
    'qr','registro','scanner','escaner','checkin','credencial','codigo',
    'lector','inscripcion','boleto','ticket','acceso','escanear','leer',
    'pase','identificacion','carnet','gafete',
  ],
  access: [
    'puerta','entrada','salida','llave','candado','cerrado','bloqueado',
    'abrir','ingresar','portero','cerradura','acceder','chapa','manija',
    'reja','cancel','portón','barda',
  ],
  security: [
    'emergencia','peligro','seguridad','amenaza','sospechoso','guardia',
    'riesgo','auxilio','pelea','violencia','robo','accidente','herido',
    'caida','golpe','desmayo','incendio','fuego','fumar','alarma',
    'evacuacion','primeros','auxilios',
  ],
  logistics: [
    'fila','cola','aglomeracion','desorden','congestion','espera',
    'organizacion','control','caos','muchedumbre','ponente','orador',
    'expositor','asistente','refrigerio','bebida','comida','almuerzo',
    'coffee','break','buffet','servicio','atencion','personal',
  ],
  climatization: [
    'aire','calor','frio','temperatura','ventilacion','acondicionado',
    'clima','caliente','fresco','humedad','abanico','ventilador','termica',
    'bochorno','sofocante','congelado','helado','sudor','fresco',
  ],
  cleaning: [
    'basura','limpieza','sucio','sanitario','bano','olor','desaseo',
    'suciedad','mugre','residuos','desechos','limpiar','aseo','higiene',
    'papel','jabon','toalla','desinfectar','agua','derrame','mojado',
    'inundacion','gotear','gotera','plomeria',
  ],
  infrastructure: [
    'silla','mesa','asiento','mobiliario','mueble','stand','instalacion',
    'estructura','techo','piso','pared','escalera','rampa','barda',
    'tapa','ventana','pupitre','podio','tribuna','tarima','escenario',
    'salon','auditorio','espacio','salon','cupo','aforo',
  ],
};

// ─── Motor de keywords ────────────────────────────────────────────────────────

function matchKeywords(tokens) {
  const scores = {};

  for (const [cat, words] of Object.entries(KEYWORD_MAP)) {
    let matches = 0;
    for (const t of tokens) {
      if (words.includes(t)) matches++;
    }
    if (matches > 0) scores[cat] = matches;
  }

  if (Object.keys(scores).length === 0) return null;

  const sorted = Object.entries(scores).sort((a, b) => b[1] - a[1]);
  const [bestCat, bestCount] = sorted[0];
  const [, secondCount] = sorted[1] ?? [null, 0];

  // Confianza basada en: cuántos keywords matchearon y qué tan claro ganó
  const base = 0.55;
  const matchBonus = Math.min(0.30, bestCount * 0.08);
  const marginBonus = Math.min(0.10, (bestCount - secondCount) * 0.05);
  const confidence = parseFloat(Math.min(0.94, base + matchBonus + marginBonus).toFixed(3));

  return {
    categoria: bestCat,
    confianza: confidence,
    prioridad: PRIORITY_BY_CATEGORY[bestCat] || 'low',
    clasificaciones: sorted.slice(0, 4).map(([c, n]) => ({
      categoria: c,
      probabilidad: parseFloat(Math.min(0.99, 0.40 + n * 0.15).toFixed(3)),
    })),
    metodo: 'keywords',
  };
}

// ─── Entrenamiento Naive Bayes (fallback para frases sin keywords claros) ─────

const classifier = new natural.BayesClassifier();

const trainingData = [
  // AUDIO
  ['no se escuchan las bocinas', 'audio'],
  ['el audio no funciona', 'audio'],
  ['las bocinas dejaron de sonar', 'audio'],
  ['el micrófono no sirve', 'audio'],
  ['no hay sonido en la sala', 'audio'],
  ['el volumen está muy bajo', 'audio'],
  ['el altavoz no suena', 'audio'],
  ['el micro no escucha', 'audio'],
  ['no se oye nada en el auditorio', 'audio'],
  ['el sonido se cortó durante la presentación', 'audio'],
  ['el bafle está apagado', 'audio'],
  ['las bocinas del salón no funcionan', 'audio'],
  ['silencio total en el auditorio el audio falló', 'audio'],
  ['el micrófono del ponente no funciona', 'audio'],
  ['micrófono inalámbrico no funciona', 'audio'],
  ['no funciona el micrófono del expositor', 'audio'],
  ['el audio del ponente se cortó', 'audio'],
  ['hay eco en los parlantes', 'audio'],
  ['el sistema de audio falla constantemente', 'audio'],
  ['no escucho nada desde mi lugar', 'audio'],

  // VIDEO
  ['el proyector no funciona', 'video'],
  ['la pantalla está apagada', 'video'],
  ['el cañón no prende', 'video'],
  ['no hay imagen en la pantalla', 'video'],
  ['el display no muestra nada', 'video'],
  ['la televisión está apagada', 'video'],
  ['el proyector está desconectado', 'video'],
  ['no se ve nada en pantalla', 'video'],
  ['el cañón del auditorio no sirve', 'video'],
  ['la pantalla del salón no enciende', 'video'],
  ['el proyector está fallando', 'video'],
  ['no prende el cañón de la sala', 'video'],
  ['la presentación no se ve', 'video'],
  ['la imagen del proyector es borrosa', 'video'],
  ['el hdmi no conecta al proyector', 'video'],
  ['no funciona el monitor', 'video'],

  // INTERNET
  ['no hay internet', 'internet'],
  ['el wifi no funciona', 'internet'],
  ['no tengo conexión a internet', 'internet'],
  ['la red está caída', 'internet'],
  ['no puedo conectarme al wifi del evento', 'internet'],
  ['la señal de internet es muy mala', 'internet'],
  ['el router no responde', 'internet'],
  ['sin conexión en el edificio', 'internet'],
  ['el wifi del edificio está caído', 'internet'],
  ['no hay señal de red', 'internet'],
  ['la conectividad está fallando', 'internet'],
  ['la red va muy lenta', 'internet'],
  ['se me cae la conexión constantemente', 'internet'],
  ['no puedo navegar', 'internet'],

  // ELECTRICAL
  ['no hay luz en el área', 'electrical'],
  ['se fue la corriente eléctrica', 'electrical'],
  ['no hay electricidad', 'electrical'],
  ['el enchufe no funciona', 'electrical'],
  ['no hay energía eléctrica en el stand', 'electrical'],
  ['se fue la luz del salón', 'electrical'],
  ['los focos están apagados', 'electrical'],
  ['el tomacorriente no sirve', 'electrical'],
  ['corte de luz en el área de exposición', 'electrical'],
  ['falta corriente eléctrica', 'electrical'],
  ['no hay donde cargar los equipos', 'electrical'],
  ['se quemó el fusible', 'electrical'],
  ['no funciona el interruptor de luz', 'electrical'],

  // REGISTRATION
  ['el qr no funciona', 'registration'],
  ['no puedo registrarme', 'registration'],
  ['el código qr no se lee', 'registration'],
  ['el scanner no funciona', 'registration'],
  ['no puedo hacer check in', 'registration'],
  ['mi credencial no sirve para registrarme', 'registration'],
  ['el lector de qr está fallando', 'registration'],
  ['no me leen el código de registro', 'registration'],
  ['el sistema de checkin no responde', 'registration'],
  ['no encuentro mi boleto', 'registration'],
  ['el código de mi inscripción no funciona', 'registration'],

  // ACCESS
  ['la puerta está cerrada con llave', 'access'],
  ['no puedo entrar al salón', 'access'],
  ['el acceso está bloqueado', 'access'],
  ['no puedo ingresar al laboratorio', 'access'],
  ['la puerta del auditorio está con seguro', 'access'],
  ['no hay quien abra la puerta', 'access'],
  ['la entrada está cerrada', 'access'],
  ['no nos dejan pasar', 'access'],
  ['el elevador no funciona', 'access'],
  ['no puedo acceder al área', 'access'],

  // SECURITY
  ['hay una emergencia en el área', 'security'],
  ['hay peligro necesito ayuda urgente', 'security'],
  ['necesito al equipo de seguridad', 'security'],
  ['hay una persona sospechosa', 'security'],
  ['emergencia en el evento', 'security'],
  ['riesgo de seguridad en el auditorio', 'security'],
  ['hay una situación de peligro', 'security'],
  ['alguien se cayó y está herido', 'security'],
  ['hay pelea entre asistentes', 'security'],
  ['se activó la alarma de incendio', 'security'],
  ['hay humo en el edificio', 'security'],

  // LOGISTICS
  ['hay demasiada fila en la entrada', 'logistics'],
  ['la entrada está congestionada', 'logistics'],
  ['hay mucha aglomeración de gente', 'logistics'],
  ['la organización está muy mal', 'logistics'],
  ['hay desorden total en la entrada', 'logistics'],
  ['la cola para entrar es muy larga', 'logistics'],
  ['no hay control en la entrada del evento', 'logistics'],
  ['mucha gente aglomerada sin control', 'logistics'],
  ['no hay agua para los ponentes', 'logistics'],
  ['falta agua para los asistentes', 'logistics'],
  ['no hay refrigerios en el área de ponentes', 'logistics'],
  ['no hay nadie que oriente a los asistentes', 'logistics'],
  ['el personal no sabe dónde está cada sala', 'logistics'],

  // CLIMATIZATION
  ['el aire acondicionado no funciona', 'climatization'],
  ['hace mucho calor en el auditorio', 'climatization'],
  ['el clima está apagado', 'climatization'],
  ['hace demasiado frío en el salón', 'climatization'],
  ['no hay ventilación en el área', 'climatization'],
  ['el aire acondicionado está apagado', 'climatization'],
  ['la temperatura está muy alta', 'climatization'],
  ['el ventilador no funciona', 'climatization'],
  ['está sofocante en el auditorio', 'climatization'],
  ['nos estamos congelando en el salón', 'climatization'],
  ['el clima está al máximo y hace mucho frío', 'climatization'],

  // CLEANING
  ['los baños están muy sucios', 'cleaning'],
  ['hay basura en el área', 'cleaning'],
  ['los sanitarios necesitan limpieza urgente', 'cleaning'],
  ['hay mal olor en los baños', 'cleaning'],
  ['el área está sucia y desaseada', 'cleaning'],
  ['los baños del edificio están en mal estado', 'cleaning'],
  ['no hay agua en los baños', 'cleaning'],
  ['los sanitarios no tienen agua', 'cleaning'],
  ['falta agua en los baños del edificio', 'cleaning'],
  ['los baños no tienen papel', 'cleaning'],
  ['no hay jabón en los baños', 'cleaning'],
  ['hay agua derramada en el piso', 'cleaning'],
  ['hay goteras en el techo', 'cleaning'],

  // INFRASTRUCTURE
  ['faltan sillas en el salón', 'infrastructure'],
  ['no hay suficientes asientos', 'infrastructure'],
  ['la mesa está rota', 'infrastructure'],
  ['el mobiliario está en mal estado', 'infrastructure'],
  ['no hay suficiente espacio para todos', 'infrastructure'],
  ['las sillas están rotas', 'infrastructure'],
  ['faltan mesas en el área de trabajo', 'infrastructure'],
  ['el escenario no está listo', 'infrastructure'],
  ['el podio está inestable', 'infrastructure'],
  ['la tarima no está bien fija', 'infrastructure'],
  ['no hay suficiente espacio en el salón', 'infrastructure'],

  // OTHER
  ['hay un problema general no identificado', 'other'],
  ['necesito reportar un incidente', 'other'],
  ['algo está mal en el evento', 'other'],
  ['problema no identificado en el evento', 'other'],
  ['no sé cómo clasificar este problema', 'other'],
];

trainingData.forEach(([text, category]) =>
  classifier.addDocument(tokenize(text).join(' '), category)
);
classifier.train();

console.log(`✅ NLP listo: ${trainingData.length} ejemplos Bayes + reglas de keywords por categoría.`);

// ─── Normalización de scores Bayes ───────────────────────────────────────────

function toConfidenceScores(classifications) {
  if (!classifications || classifications.length === 0) return [];
  const sorted = [...classifications].sort((a, b) => b.value - a.value);
  const best = sorted[0].value;
  const worst = sorted[sorted.length - 1].value;
  const range = best - worst || 1;
  return sorted.map((c) => ({
    label: c.label,
    prob: parseFloat(((c.value - worst) / range).toFixed(3)),
  }));
}

// ─── Similitud Dice ───────────────────────────────────────────────────────────

function diceCoefficient(tokens1, tokens2) {
  const set1 = new Set(tokens1);
  const set2 = new Set(tokens2);
  if (set1.size === 0 || set2.size === 0) return 0;
  const intersection = [...set1].filter((t) => set2.has(t)).length;
  return (2 * intersection) / (set1.size + set2.size);
}

// ─── API pública ──────────────────────────────────────────────────────────────

function analizar(texto) {
  if (!texto || texto.trim().length < 3) {
    return { categoria: 'other', confianza: 0.3, prioridad: 'low', palabrasClave: [], clasificaciones: [], metodo: 'none' };
  }

  const tokens = tokenize(texto);
  if (tokens.length === 0) {
    return { categoria: 'other', confianza: 0.3, prioridad: 'low', palabrasClave: [], clasificaciones: [], metodo: 'none' };
  }

  // 1️⃣ Intenta keywords primero (más confiable)
  const kwResult = matchKeywords(tokens);
  if (kwResult) {
    return { ...kwResult, palabrasClave: tokens.slice(0, 6) };
  }

  // 2️⃣ Fallback: Naive Bayes
  const classifications = classifier.getClassifications(tokens.join(' '));
  const sorted = toConfidenceScores(classifications);
  const best = sorted[0];
  const second = sorted[1];

  const margin = best.prob - (second?.prob ?? 0);
  const isUncertain = best.prob < 0.25 || margin < 0.12;

  const categoria = isUncertain ? 'other' : best.label;
  const rawConf = isUncertain ? best.prob * 0.5 : best.prob;
  const confianza = parseFloat(Math.min(0.90, Math.max(0.30, rawConf)).toFixed(3));

  return {
    categoria,
    confianza,
    prioridad: PRIORITY_BY_CATEGORY[categoria] || 'low',
    palabrasClave: tokens.slice(0, 6),
    clasificaciones: sorted.slice(0, 4).map((c) => ({
      categoria: c.label,
      probabilidad: parseFloat(Math.min(0.99, Math.max(0, c.prob)).toFixed(3)),
    })),
    metodo: 'bayes',
  };
}

function buscarSimilares(texto, incidencias, umbral = 0.25) {
  if (!texto || texto.trim().length < 8 || !Array.isArray(incidencias)) return [];
  const tokensEntrada = tokenize(texto);
  if (tokensEntrada.length === 0) return [];

  return incidencias
    .map((inc) => ({
      id: inc.id,
      similitud: parseFloat(diceCoefficient(tokensEntrada, tokenize(inc.descripcion || '')).toFixed(3)),
    }))
    .filter((r) => r.similitud >= umbral)
    .sort((a, b) => b.similitud - a.similitud)
    .slice(0, 3);
}

module.exports = { analizar, buscarSimilares };
