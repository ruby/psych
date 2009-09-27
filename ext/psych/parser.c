#include <psych.h>

static VALUE parse_string(VALUE self, VALUE string)
{
  yaml_parser_t parser;
  yaml_event_t event;

  yaml_parser_initialize(&parser);

  yaml_parser_set_input_string(
      &parser,
      StringValuePtr(string),
      RSTRING_LEN(string)
  );

  int done = 0;

  VALUE handler = rb_iv_get(self, "@handler");

  while(!done) {
    if(!yaml_parser_parse(&parser, &event)) {
      yaml_parser_delete(&parser);
      rb_raise(rb_eRuntimeError, "couldn't parse YAML");
    }

    switch(event.type) {
      case YAML_STREAM_START_EVENT:
        rb_funcall(handler, rb_intern("start_stream"), 1,
            INT2NUM((long)event.data.stream_start.encoding)
        );
        break;
      case YAML_DOCUMENT_START_EVENT:
        {
          VALUE version = event.data.document_start.version_directive ?
            rb_ary_new3(
              (long)2,
              INT2NUM((long)event.data.document_start.version_directive->major),
              INT2NUM((long)event.data.document_start.version_directive->minor)
            ) : rb_ary_new();
          rb_funcall(handler, rb_intern("start_document"), 1, version);
        }
        break;
      case YAML_STREAM_END_EVENT:
        rb_funcall(handler, rb_intern("end_stream"), 0);
        done = 1;
        break;
    }
  }

  return self;
}

VALUE cPsychParser;

void Init_psych_parser()
{
  cPsychParser = rb_define_class_under(mPsych, "Parser", rb_cObject);

  rb_define_private_method(cPsychParser, "parse_string", parse_string, 1);
}
