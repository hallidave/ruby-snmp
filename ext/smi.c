/**********************************************************************
  Copyright (c) 2005 David R. Halliday
  All rights reserved.

  This SNMP library is free software.  Redistribution is permitted
  under the same terms and conditions as the standard Ruby
  distribution.  See the COPYING file in the Ruby distribution for
  details.
**********************************************************************/

#include "ruby.h"
#include "smi.h" 
#include <errno.h>

#define NODE_KINDS (SMI_NODEKIND_NODE | SMI_NODEKIND_TABLE | SMI_NODEKIND_ROW | SMI_NODEKIND_COLUMN | SMI_NODEKIND_SCALAR | SMI_NODEKIND_NOTIFICATION)

static VALUE
get_oid_hash(SmiModule* module)
{
  VALUE hash;
  SmiNode* node;
      
  hash = rb_hash_new();
  node = smiGetFirstNode(module, NODE_KINDS);
  while (node != NULL) {
    char* oid_string;
    VALUE name;
    VALUE oid;

    oid_string = smiRenderOID(node->oidlen, node->oid, SMI_RENDER_NUMERIC);
    name = rb_str_new2(node->name);
    oid = rb_str_new2(oid_string);
    rb_hash_aset(hash, name, oid);
    node = smiGetNextNode(node, NODE_KINDS);
  }
  
  return hash;
}

/*
 * Reads the named file as an SMI module.  Returns an array containing
 * the module name and a Hash with OID symbols as keys and the numeric
 * OIDs as values.
 */
static VALUE
fsmi_load_smi_module(VALUE self, VALUE filename)
{
  int init_ret;
  char* load_ret;
  char* cfilename;
  SmiModule* module;
  VALUE module_name;
  VALUE oid_hash;

  init_ret = smiInit(NULL); 
  if (init_ret != 0) {
    rb_raise(rb_eRuntimeError, "libsmi init error: %d", init_ret);
  }
  
  cfilename = STR2CSTR(filename);
  load_ret = smiLoadModule(cfilename);
  
  if (load_ret == NULL) {
    rb_raise(rb_eRuntimeError, "%s for module '%s'", strerror(errno), cfilename);
  }
  
  module = smiGetFirstModule();
  if (module == NULL) {
      rb_raise(rb_eRuntimeError, "No module found in %s", cfilename);
  }
  
  module_name = rb_str_new2(module->name);
  oid_hash = get_oid_hash(module);
  
  return rb_ary_new3(2, module_name, oid_hash);
}

void
Init_smi()
{
  VALUE mSNMP = rb_define_module("SNMP");
  VALUE mSMI = rb_define_module_under(mSNMP, "SMI");
  rb_define_method(mSMI, "load_smi_module", fsmi_load_smi_module, 1);        
}
