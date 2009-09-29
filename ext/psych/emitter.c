#include <psych.h>

VALUE cPsychEmitter;

static int writer(void *ctx, unsigned char *buffer, size_t size)
{
  VALUE io = (VALUE)ctx;
  VALUE str = rb_str_new(buffer, size);
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
  Data_Wrap_Struct(cPsychEmitter, 0, dealloc, emitter);
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
  yaml_stream_start_event_initialize(&event, NUM2INT(encoding));
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
}
