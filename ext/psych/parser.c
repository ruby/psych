#include <psych.h>

static VALUE parse_string(VALUE self, VALUE string)
{
  yaml_parser_t parser;
  yaml_event_t event;

  yaml_parser_initialize(&parser);

  yaml_parser_set_input_string(
      &parser,
      (const unsigned char *)StringValuePtr(string),
      (size_t)RSTRING_LEN(string)
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
                  start->handle ? rb_str_new2((const char *)start->handle) : Qnil,
                  start->prefix ? rb_str_new2((const char *)start->prefix) : Qnil
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
          rb_str_new2((const char *)event.data.alias.anchor) :
          Qnil
        );
        break;
      case YAML_SCALAR_EVENT:
        {
          VALUE val = rb_str_new(
              (const char *)event.data.scalar.value,
              (long)event.data.scalar.length
          );

          VALUE anchor = event.data.scalar.anchor ?
            rb_str_new2((const char *)event.data.scalar.anchor) :
            Qnil;

          VALUE tag = event.data.scalar.tag ?
            rb_str_new2((const char *)event.data.scalar.tag) :
            Qnil;

          VALUE plain_implicit =
            event.data.scalar.plain_implicit == 0 ? Qfalse : Qtrue;

          VALUE quoted_implicit =
            event.data.scalar.quoted_implicit == 0 ? Qfalse : Qtrue;

          VALUE style = INT2NUM((long)event.data.scalar.style);

          rb_funcall(handler, rb_intern("scalar"), 6,
              val, anchor, tag, plain_implicit, quoted_implicit, style);
        }
        break;
      case YAML_SEQUENCE_START_EVENT:
        {
          VALUE anchor = event.data.sequence_start.anchor ?
            rb_str_new2((const char *)event.data.sequence_start.anchor) :
            Qnil;

          VALUE tag = event.data.sequence_start.tag ?
            rb_str_new2((const char *)event.data.sequence_start.tag) :
            Qnil;

          VALUE implicit =
            event.data.sequence_start.implicit == 0 ? Qfalse : Qtrue;

          VALUE style = INT2NUM((long)event.data.sequence_start.style);

          rb_funcall(handler, rb_intern("start_sequence"), 4,
              anchor, tag, implicit, style);
        }
        break;
      case YAML_SEQUENCE_END_EVENT:
        rb_funcall(handler, rb_intern("end_sequence"), 0);
        break;
      case YAML_MAPPING_START_EVENT:
        {
          VALUE anchor = event.data.mapping_start.anchor ?
            rb_str_new2((const char *)event.data.mapping_start.anchor) :
            Qnil;

          VALUE tag = event.data.mapping_start.tag ?
            rb_str_new2((const char *)event.data.mapping_start.tag) :
            Qnil;

          VALUE implicit =
            event.data.mapping_start.implicit == 0 ? Qfalse : Qtrue;

          VALUE style = INT2NUM((long)event.data.mapping_start.style);

          rb_funcall(handler, rb_intern("start_mapping"), 4,
              anchor, tag, implicit, style);
        }
        break;
      case YAML_MAPPING_END_EVENT:
        rb_funcall(handler, rb_intern("end_mapping"), 0);
        break;
      case YAML_NO_EVENT:
        rb_funcall(handler, rb_intern("empty"), 0);
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
