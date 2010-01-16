#include <psych.h>

VALUE cPsychVisitorsToRuby;

static VALUE build_exception(VALUE self, VALUE klass, VALUE mesg)
{
  VALUE e = rb_obj_alloc(klass);

  rb_iv_set(e, "mesg", mesg);

  return e;
}

static VALUE path2class(VALUE self, VALUE path)
{
  return rb_path_to_class(path);
}

void Init_psych_to_ruby(void)
{
  VALUE psych     = rb_define_module("Psych");
  VALUE visitors  = rb_define_module_under(psych, "Visitors");
  VALUE visitor   = rb_define_class_under(visitors, "Visitor", rb_cObject);
  cPsychVisitorsToRuby = rb_define_class_under(visitors, "ToRuby", visitor);

  rb_define_private_method(cPsychVisitorsToRuby, "build_exception", build_exception, 2);
  rb_define_private_method(cPsychVisitorsToRuby, "path2class", path2class, 1);
}
