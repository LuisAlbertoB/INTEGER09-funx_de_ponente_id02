# Diagrama Relacional de la Base de Datos (Prisma Schema)

```mermaid
erDiagram
    Rol {
        admin
        ponente
        coordinador
        participante
        asistente
        usuario_general
    }
    EstadoSolicitud {
        pendiente
        aprobada
        rechazada
        cancelada
    }
    TipoSolicitud {
        normal
        especial
    }
    NivelAcademico {
        undergraduate
        postgraduate
        ambos
    }
    TipoMaterial {
        pdf
        pptx
        video
        link
        imagen
        otro
    }
    Genero {
        hombre
        mujer
        otro
        prefiero_no_decir
    }
    ParticipationLevel {
        pasivo
        activo
        muy_activo
    }
    SentimientoGeneral {
        positivo
        neutral
        negativo
    }

    Usuario {
        Int id_usuario PK
        String nombre_completo
        String matricula UK
        String contrasena
        Rol rol
        Int estado
        DateTime created_at
        DateTime updated_at
        Int id_user_creator FK
    }

    Edificio {
        Int id_edificio PK
        String nombre_clave
        Int estado
        DateTime created_at
        DateTime updated_at
    }

    Aula {
        Int id_aula PK
        String nombre_clave
        Int estado
        Int id_edificio FK
        Int id_owner FK
        DateTime created_at
        DateTime updated_at
    }

    CatalogoInmobiliario {
        Int id_inmobiliario PK
        String categoria
        String nombre
        String modelo
        String num_de_serie UK
        Int stock_disponible
        DateTime created_at
        DateTime updated_at
    }

    Periodo {
        Int id_periodo PK
        String nombre_clave
        DateTime fecha_inicio
        DateTime fecha_final
        Int estado
        DateTime created_at
        DateTime updated_at
    }

    Actividad {
        Int id_actividad PK
        String titulo_actividad
        String subtitulo_actividad
        String descripcion
        DateTime created_at
        DateTime updated_at
    }

    Solicitud {
        Int id_solicitud PK
        TipoSolicitud tipo_solicitud
        DateTime fecha_inicio
        DateTime fecha_final
        String motivo
        EstadoSolicitud estado
        Int id_user_solicitante FK
        Int id_aula FK
        Int id_periodo FK
        Int id_actividad FK
        DateTime created_at
        DateTime updated_at
    }

    SolicitudInmobiliario {
        Int id_solicitud_inmobiliario PK
        Int cantidad_solicitada
        EstadoSolicitud estado
        DateTime fecha_inicio
        DateTime fecha_fin
        Int id_user_solicitante FK
        Int id_inmobiliario_solicitado FK
        Int id_periodo FK
        DateTime created_at
        DateTime updated_at
    }

    SolicitudHasSolicitudInmobiliario {
        Int id PK
        Int id_solicitud FK
        Int id_solicitud_inmobiliario FK
        DateTime created_at
        DateTime updated_at
    }

    AulaHasMobiliarioInfraestructura {
        Int id_aula_has_mobiliario_infraestructura PK
        Int id_aula FK
        Int id_mobiliario FK
        Int cantidad_en_aula
        DateTime created_at
        DateTime updated_at
    }

    Reporte {
        Int id_reporte PK
        String titulo
        String descripcion
        Int id_user_reportante FK
        Int id_aula FK
        Int id_mobiliario_afectado FK
        Int id_periodo FK
        DateTime created_at
        DateTime updated_at
    }

    BitacoraMantenimiento {
        Int id_bitacora_mantenimiento PK
        DateTime fecha_inicio
        DateTime fecha_final
        String accion_realizada
        String descripcion
        String realizado_por
        Int id_mobiliario FK
        Int id_aula FK
        Int id_periodo FK
        DateTime created_at
        DateTime updated_at
    }

    Conferencia {
        Int id_conferencia PK
        String titulo
        String descripcion
        String tematica
        NivelAcademico nivel_academico_objetivo
        Int duracion_estimada_min
        DateTime fecha_realizada
        Int estado
        Int id_ponente FK
        Int id_actividad FK
        Int id_aula_utilizada FK
        Int id_periodo FK
        DateTime created_at
        DateTime updated_at
    }

    MaterialDeApoyo {
        Int id_material PK
        TipoMaterial tipo_archivo
        String titulo_material
        String url_almacenamiento
        Int tamanio_bytes
        Boolean publico
        Int id_conferencia FK
        DateTime created_at
        DateTime updated_at
    }

    RegistroEvento {
        Int id_registro PK
        Int num_asistentes_real
        Int num_participantes_registrados
        Decimal porcentaje_asistencia
        String comentario_general_ponente
        Int id_conferencia FK UK
        DateTime created_at
        DateTime updated_at
    }

    FeedbackAsistente {
        Int id_feedback PK
        NivelAcademico nivel_academico
        String specialty
        Genero genero
        Int duracion_interaccion_min
        Int total_interacciones
        Int tareas_completadas
        Decimal porcentaje_aciertos
        Decimal calificacion
        ParticipationLevel participation_level
        SentimientoGeneral sentimiento_general
        Int score_logistica
        Int score_contenido
        String comentario_escrito
        String fuente
        Int id_conferencia FK
        Int id_usuario FK
        DateTime created_at
    }

    ComentarioForo {
        Int id_comentario PK
        String mensaje
        Int id_evento FK
        Int id_usuario FK
        Int id_comentario_padre FK
        DateTime created_at
    }

    EvaluacionEvento {
        Int id_evaluacion PK
        Decimal calificacion
        Int porcentaje_satisfaccion
        String comentario_escrito
        Int id_evento FK
        Int id_usuario FK
        DateTime created_at
    }

    Usuario ||--o{ Usuario : "crea (id_user_creator)"
    Usuario ||--o{ Aula : "es dueño de (id_owner)"
    Usuario ||--o{ Solicitud : "solicita"
    Usuario ||--o{ SolicitudInmobiliario : "solicita"
    Usuario ||--o{ Reporte : "reporta"
    Usuario ||--o{ Conferencia : "dicta"
    Usuario ||--o{ FeedbackAsistente : "da"
    Usuario ||--o{ ComentarioForo : "escribe"
    Usuario ||--o{ EvaluacionEvento : "evalúa"

    Edificio ||--o{ Aula : "contiene"

    Aula ||--o{ Solicitud : "es asignada"
    Aula ||--o{ Reporte : "recibe"
    Aula ||--o{ BitacoraMantenimiento : "registra"
    Aula ||--o{ AulaHasMobiliarioInfraestructura : "tiene"
    Aula ||--o{ Conferencia : "alberga"

    CatalogoInmobiliario ||--o{ SolicitudInmobiliario : "es pedido"
    CatalogoInmobiliario ||--o{ Reporte : "es afectado"
    CatalogoInmobiliario ||--o{ BitacoraMantenimiento : "mantenido"
    CatalogoInmobiliario ||--o{ AulaHasMobiliarioInfraestructura : "asignado"

    Periodo ||--o{ Solicitud : "agrupa"
    Periodo ||--o{ SolicitudInmobiliario : "agrupa"
    Periodo ||--o{ Reporte : "agrupa"
    Periodo ||--o{ BitacoraMantenimiento : "agrupa"
    Periodo ||--o{ Conferencia : "agrupa"

    Actividad ||--o{ Solicitud : "justifica"
    Actividad ||--o{ Conferencia : "categoriza"

    Solicitud ||--o{ SolicitudHasSolicitudInmobiliario : "vincula"
    SolicitudInmobiliario ||--o{ SolicitudHasSolicitudInmobiliario : "vincula"

    Conferencia ||--o{ MaterialDeApoyo : "contiene"
    Conferencia ||--o1 RegistroEvento : "registra"
    Conferencia ||--o{ FeedbackAsistente : "recibe"
    Conferencia ||--o{ ComentarioForo : "genera"
    Conferencia ||--o{ EvaluacionEvento : "recibe"

    ComentarioForo ||--o{ ComentarioForo : "tiene respuesta (id_comentario_padre)"
```
