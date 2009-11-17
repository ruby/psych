#include <psych.h>

VALUE cPsychVisitorsToRuby;

static VALUE build_exception(VALUE self, VALUE klass, VALUE mesg)
{
  VALUE e = rb_obj_alloc(klass);

  rb_iv_set(e, "mesg", mesg);

  return e;
}

void Init_psych_to_ruby(void)
{
  VALUE psych     = rb_define_module("Psych");
  VALUE visitors  = rb_define_module_under(psych, "Visitors");
  VALUE visitor   = rb_define_class_under(visitors, "Visitor", rb_cObject);
  cPsychVisitorsToRuby = rb_define_class_under(visitors, "ToRuby", visitor);

  rb_define_method(cPsychVisitorsToRuby, "build_exception", build_exception, 2);
}
