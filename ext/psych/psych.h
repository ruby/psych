#ifndef PSYCH_H
#define PSYCH_H

#include <ruby.h>
#include <yaml.h>

#define PSYCH_ASSOCIATE_ENCODING(_value, _encoding) \
  ({ \
    switch(_encoding) { \
      case YAML_ANY_ENCODING: \
        break; \
      case YAML_UTF8_ENCODING: \
        rb_enc_associate_index(_value, rb_enc_find_index("UTF-8"));\
        break; \
      case YAML_UTF16LE_ENCODING: \
        rb_enc_associate_index(_value, rb_enc_find_index("UTF-16LE"));\
        break; \
      case YAML_UTF16BE_ENCODING: \
        rb_enc_associate_index(_value, rb_enc_find_index("UTF-16BE"));\
        break; \
      default:\
        break; \
    }\
   })

#include <parser.h>
#include <emitter.h>
#include <to_ruby.h>
#include <yaml_tree.h>

extern VALUE mPsych;


#endif
