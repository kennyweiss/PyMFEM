%module(package="mfem._par", directors="0")  gridfunc
%{
  #include <fstream>  
  #include <iostream>
  #include <sstream>
  #include <limits>
  #include <cmath>
  #include <cstring>
  #include <ctime>
  #include "fem/linearform.hpp"
  #include "fem/gridfunc.hpp"
  #include "pycoefficient.hpp"
  #include "numpy/arrayobject.h"
  #include "io_stream.hpp"        
%}

%init %{
import_array();
%}

%include "../common/cpointers.i"
%include "exception.i"

%include "std_string.i"

%import "array.i"
%import "vector.i"
%import "coefficient.i"
%import "fespace.i"
%import "bilininteg.i"
%import "linearform.i"
%import "fespace.i"
%import "fe_coll.i"
%import "intrules.i"
%import "densemat.i"
%import "sparsemat.i"
%import "lininteg.i"
%import "eltrans.i"

%import "../common/io_stream_typemap.i"
OSTREAM_TYPEMAP(std::ostream&)

%rename(Assign) mfem::GridFunction::operator=;

%feature("shadow") mfem::GridFunction::GetNodalValues%{
def GetNodalValues(self, *args):
    '''
    GetNodalValues(i)   ->   GetNodalValues(vector, vdim)
    GetNodalValues(i, array<dobule>, vdim)
    '''
    from .vector import Vector
    if len(args) == 1:
        vec = Vector()
        _gridfunc.GridFunction_GetNodalValues(self, vec, args[0])
        vec.thisown = 0
        return vec.GetDataArray()
    else:
        return _gridfunc.GridFunction_GetNodalValues(self, *args)
%}

%typemap(in) const mfem::IntegrationRule *irs[]{
  if (PyList_Check($input)) {
    int size = PyList_Size($input);
    int i = 0;
    $1 = (mfem::IntegrationRule **) malloc((size)*sizeof(mfem::IntegrationRule *));
    for (i = 0; i < size; i++) {
       PyObject *o = PyList_GetItem($input,i);
       void *temp;       
       if (SWIG_ConvertPtr(o, &temp,
	   $descriptor(mfem::IntegrationRule *),SWIG_POINTER_EXCEPTION) == -1){
           return NULL;
       }
       $1[i] = reinterpret_cast<mfem::IntegrationRule *>(temp);       
     }
  } else {
    PyErr_SetString(PyExc_TypeError,"not a list");
    return NULL;
  }
}
%typemap(typecheck) const mfem::IntegrationRule *irs[]{
   $1 = PyList_Check($input) ? 1 : 0;
}

%include "../common/exception.i"
%include "fem/gridfunc.hpp"

namespace mfem{
%extend GridFunction{
GridFunction(Mesh *m, const char *grid_file){
   mfem::GridFunction *gf;
   std::ifstream igrid(grid_file);
   if (!igrid) {
      std::cerr << "\nCan not open grid function file: " << grid_file << '\n' << std::endl;
      return NULL;
   }
   gf = new mfem::GridFunction(m, igrid);
   return gf;
}
GridFunction(mfem::FiniteElementSpace *fes, const mfem::Vector &v, int offset){
   mfem::GridFunction *gf;   
   gf = new mfem::GridFunction(fes, v.GetData() + offset);
   return gf;
}
 
void SaveToFile(const char *gf_file, const int precision) const
   {
        std::cerr << "\nWarning Deprecated : Use Save(filename) insteead of SaveToFile \n";  
	std::ofstream mesh_ofs(gf_file);	
        mesh_ofs.precision(precision);
        self->Save(mesh_ofs);	
   }

PyObject* WriteToStream(PyObject* StringIO) const  {
    PyObject* module = PyImport_ImportModule("io");
    if (!module){
   	 PyErr_SetString(PyExc_RuntimeError, "Can not load io module");
         return (PyObject *) NULL;
    }      
    PyObject* cls = PyObject_GetAttrString(module, "StringIO");
    if (!cls){
   	 PyErr_SetString(PyExc_RuntimeError, "Can not load StringIO");
         return (PyObject *) NULL;
    }      
    int check = PyObject_IsInstance(StringIO, cls);
    Py_DECREF(module);
    if (! check){
 	 PyErr_SetString(PyExc_TypeError, "First argument must be IOString");
         return (PyObject *) NULL;
    }
    std::ostringstream stream;
    self->Save(stream);
    std::string str =  stream.str();
    const char* s = str.c_str();
    const int n = str.length();
    PyObject *ret = PyObject_CallMethod(StringIO, "write", "s#", s, static_cast<Py_ssize_t>(n));
    if (PyErr_Occurred()) {
       PyErr_SetString(PyExc_RuntimeError, "Error occured when writing IOString");
       return (PyObject *) NULL;
    }
    return ret;      
}
 
GridFunction & iadd(GridFunction &c)
   {
      *self += c;
      return *self;
   }
GridFunction & isub(GridFunction &c)
   {
      *self -= c;
      return *self;
   }
GridFunction & isub(double c)
   {
      *self -= c;
      return *self;
   }
GridFunction & imul(double c)
  {
   (* self) *= c;
   return *self;
   }
GridFunction & idiv(double c)
   {
      * self /= c;
      return *self;
   }
  }
}  // end of namespace

%pythoncode %{
def __iadd__(self, v):
    ret = _gridfunc.GridFunction_iadd(self, v)
    ret.thisown = 0
    return self
def __isub__(self, v):
    ret = _gridfunc.GridFunction_isub(self, v)
    ret.thisown = 0
    return self
def __idiv__(self, v):
    ret = _gridfunc.GridFunction_idiv(self, v)
    ret.thisown = 0
    return self
def __imul__(self, v):
    ret = _gridfunc.GridFunction_imul(self, v)
    ret.thisown = 0
    return self
      
GridFunction.__iadd__  = __iadd__
GridFunction.__idiv__  = __idiv__
GridFunction.__isub__  = __isub__
GridFunction.__imul__  = __imul__      
%} 

/*
fem/gridfunc.hpp:   virtual void Save(std::ostream &out) const;
fem/gridfunc.hpp:   void Save(std::ostream &out) const;

fem/gridfunc.hpp:   void SaveSTLTri(std::ostream &out, double p1[], double p2[], double p3[]);
fem/gridfunc.hpp:   void SaveVTK(std::ostream &out, const std::string &field_name, int ref);
fem/gridfunc.hpp:   void SaveSTL(std::ostream &out, int TimesToRefine = 1);
*/

OSTREAM_ADD_DEFAULT_FILE(GridFunction, Save)
OSTREAM_ADD_DEFAULT_FILE(QuadratureFunction, Save)
