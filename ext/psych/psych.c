#include <psych.h>

static VALUE libyaml_version(VALUE module)
{
  int major, minor, patch;

  yaml_get_version(&major, &minor, &patch);

  VALUE list[3] = {
    INT2NUM((long)major),
    INT2NUM((long)minor),
    INT2NUM((long)patch)
  };

  return rb_ary_new4((long)3, list);
}

VALUE mPsych;

void Init_psych()
{
  mPsych = rb_define_module("Psych");

  rb_define_singleton_method(mPsych, "libyaml_version", libyaml_version, 0);

  Init_psych_parser();
  Init_psych_emitter();
}
