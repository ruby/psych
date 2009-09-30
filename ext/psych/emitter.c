#include <psych.h>

VALUE cPsychEmitter;

static void emit(yaml_emitter_t * emitter, yaml_event_t * event)
{
  if(!yaml_emitter_emit(emitter, event))
    rb_raise(rb_eRuntimeError, emitter->problem);
}

static int writer(void *ctx, unsigned char *buffer, size_t size)
{
  VALUE io = (VALUE)ctx;
  VALUE str = rb_str_new((const char *)buffer, (long)size);
  VALUE wrote = rb_funcall(io, rb_intern("write"), 1, str);
  return (int)NUM2INT(wrote);
}

static void dealloc(yaml_emitter_t * emitter)
{
  yaml_emitter_delete(emitter);
  free(emitter);
}

static VALUE allocate(VALUE klass)
{
  yaml_emitter_t * emitter = malloc(sizeof(yaml_emitter_t));
  yaml_emitter_initialize(emitter);
  return Data_Wrap_Struct(cPsychEmitter, 0, dealloc, emitter);
}

static VALUE initialize(VALUE self, VALUE io)
{
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_emitter_set_output(emitter, writer, (void *)io);

  return self;
}

static VALUE start_stream(VALUE self, VALUE encoding)
{
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_stream_start_event_initialize(&event, (yaml_encoding_t)NUM2INT(encoding));

  emit(emitter, &event);

  return self;
}

static VALUE end_stream(VALUE self)
{
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_stream_end_event_initialize(&event);

  emit(emitter, &event);

  return self;
}

static VALUE start_document(VALUE self, VALUE version, VALUE tags, VALUE imp)
{
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_version_directive_t version_directive;

  if(RARRAY_LEN(version) > 0) {
    VALUE major = rb_ary_entry(version, (long)0);
    VALUE minor = rb_ary_entry(version, (long)1);

    version_directive.major = NUM2INT(major);
    version_directive.minor = NUM2INT(minor);
  }

  yaml_event_t event;
  yaml_document_start_event_initialize(
      &event,
      (RARRAY_LEN(version) > 0) ? &version_directive : NULL,
      NULL,
      NULL,
      imp == Qtrue ? 1 : 0
  );

  emit(emitter, &event);

  return self;
}

static VALUE end_document(VALUE self, VALUE imp)
{
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_document_end_event_initialize(&event, imp == Qtrue ? 1 : 0);

  emit(emitter, &event);

  return self;
}

static VALUE scalar(
    VALUE self,
    VALUE value,
    VALUE anchor,
    VALUE tag,
    VALUE plain,
    VALUE quoted,
    VALUE style
) {
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_scalar_event_initialize(
      &event,
      (yaml_char_t *)(Qnil == anchor ? NULL : StringValuePtr(anchor)),
      (yaml_char_t *)(Qnil == tag ? NULL : StringValuePtr(tag)),
      (yaml_char_t*)StringValuePtr(value),
      (int)RSTRING_LEN(value),
      Qtrue == plain ? 1 : 0,
      Qtrue == quoted ? 1 : 0,
      (yaml_scalar_style_t)NUM2INT(style)
  );

  emit(emitter, &event);

  return self;
}

static VALUE start_sequence(
    VALUE self,
    VALUE anchor,
    VALUE tag,
    VALUE implicit,
    VALUE style
) {
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_sequence_start_event_initialize(
      &event,
      (yaml_char_t *)(Qnil == anchor ? NULL : StringValuePtr(anchor)),
      (yaml_char_t *)(Qnil == anchor ? NULL : StringValuePtr(tag)),
      Qtrue == implicit ? 1 : 0,
      (yaml_sequence_style_t)NUM2INT(style)
  );

  emit(emitter, &event);

  return self;
}

static VALUE end_sequence(VALUE self)
{
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_sequence_end_event_initialize(&event);

  emit(emitter, &event);

  return self;
}

static VALUE start_mapping(
    VALUE self,
    VALUE anchor,
    VALUE tag,
    VALUE implicit,
    VALUE style
) {
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_mapping_start_event_initialize(
      &event,
      (yaml_char_t *)(Qnil == anchor ? NULL : StringValuePtr(anchor)),
      (yaml_char_t *)(Qnil == anchor ? NULL : StringValuePtr(tag)),
      Qtrue == implicit ? 1 : 0,
      (yaml_sequence_style_t)NUM2INT(style)
  );

  emit(emitter, &event);

  return self;
}

static VALUE end_mapping(VALUE self)
{
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_mapping_end_event_initialize(&event);

  emit(emitter, &event);

  return self;
}

static VALUE alias(VALUE self, VALUE anchor)
{
  yaml_emitter_t * emitter;
  Data_Get_Struct(self, yaml_emitter_t, emitter);

  yaml_event_t event;
  yaml_alias_event_initialize(
      &event,
      (yaml_char_t *)(Qnil == anchor ? NULL : StringValuePtr(anchor))
  );

  emit(emitter, &event);

  return self;
}

void Init_psych_emitter()
{
  VALUE psych     = rb_define_module("Psych");
  VALUE handler   = rb_define_class_under(psych, "Handler", rb_cObject); 
  cPsychEmitter   = rb_define_class_under(psych, "Emitter", handler);

  rb_define_alloc_func(cPsychEmitter, allocate);

  rb_define_method(cPsychEmitter, "initialize", initialize, 1);
  rb_define_method(cPsychEmitter, "start_stream", start_stream, 1);
  rb_define_method(cPsychEmitter, "end_stream", end_stream, 0);
  rb_define_method(cPsychEmitter, "start_document", start_document, 3);
  rb_define_method(cPsychEmitter, "end_document", end_document, 1);
  rb_define_method(cPsychEmitter, "scalar", scalar, 6);
  rb_define_method(cPsychEmitter, "start_sequence", start_sequence, 4);
  rb_define_method(cPsychEmitter, "end_sequence", end_sequence, 0);
  rb_define_method(cPsychEmitter, "start_mapping", start_mapping, 4);
  rb_define_method(cPsychEmitter, "end_mapping", end_mapping, 0);
  rb_define_method(cPsychEmitter, "alias", alias, 1);
}
