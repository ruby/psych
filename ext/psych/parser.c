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
          // Grab the document version
          VALUE version = event.data.document_start.version_directive ?
            rb_ary_new3(
              (long)2,
              INT2NUM((long)event.data.document_start.version_directive->major),
              INT2NUM((long)event.data.document_start.version_directive->minor)
            ) : rb_ary_new();

          // Get a list of tag directives (if any)
          VALUE tag_directives = rb_ary_new();
          if(event.data.document_start.tag_directives.start) {
            yaml_tag_directive_t *start =
              event.data.document_start.tag_directives.start;
            yaml_tag_directive_t *end =
              event.data.document_start.tag_directives.end;
            for(; start != end; start++) {
              VALUE pair = rb_ary_new3((long)2,
                  start->handle ? rb_str_new2(start->handle) : Qnil,
                  start->prefix ? rb_str_new2(start->prefix) : Qnil
              );
              rb_ary_push(tag_directives, pair);
            }
          }
          rb_funcall(handler, rb_intern("start_document"), 3,
              version, tag_directives,
              event.data.document_start.implicit == 1 ? Qtrue : Qfalse
          );
        }
        break;
      case YAML_DOCUMENT_END_EVENT:
        rb_funcall(handler, rb_intern("end_document"), 1,
            event.data.document_end.implicit == 1 ? Qtrue : Qfalse
        );
        break;
      case YAML_ALIAS_EVENT:
        rb_funcall(handler, rb_intern("alias"), 1,
          event.data.alias.anchor ?
          rb_str_new2(event.data.alias.anchor) :
          Qnil
        );
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
