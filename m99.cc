#include <boost/python.hpp>
#include <boost/python/module.hpp>
#include <boost/python/class.hpp>
#include <boost/python/iterator.hpp>
#include <boost/python/stl_iterator.hpp>
#include <vector>
#include <list>
#include <algorithm>
#include <iterator>
#include <iostream>
#include <string>

using namespace boost::python;

using vec = std::vector<std::string> ;

class aa:public std::vector<std::string> {
public:
  void append(const std::string & s) {
    push_back(s);
  }
  aa(){
    push_back("whats");
    push_back("up");
  }
  std::string getitem (int i) const { return at(i); }
};

void append_it(vec & v, const std::string & s) { v.push_back(s); }
std::string get_it(const vec & v, int i) { return v[i]; }

template<typename T>
void list_assign(std::list<T>& l, object o) {
    // Turn a Python sequence into an STL input range
    stl_input_iterator<T> begin(o), end;
    l.assign(begin, end);
}

template<typename T>
void vector_assign(std::vector<T>& l, object o) {
    // Turn a Python sequence into an STL input range
    stl_input_iterator<T> begin(o), end;
    l.assign(begin, end);
}

BOOST_PYTHON_MODULE(m99)
{
    //class_<vec>("vec").def("getit",get_it);
    def ("append_it",append_it);
    def ("get_it",get_it);

    class_<aa>("dvec")
        .def("__iter__", iterator<aa>())
        .def("__getitem__", &aa::getitem)
        .def("__len__", &aa::size)
        .def("append", &aa::append);

// Part of the wrapper for list<int>
class_<std::list<int> >("list_int")
    .def("assign", &list_assign<int>);
class_<std::vector<int> >("vector_int")
    .def("assign", &vector_assign<int>)
    .def("__getitem__",+[](const std::vector<int> &obj, int i) {return obj.at(i);} );
//def("strvec_to_list" , +[] (const std::vector<std::string> &src){ list L; for(auto &s: src) {L.append(s);} return L;});
def("newvec" , +[] { std::vector<std::string> v; return v;});
class_<std::vector<std::string> >("vector_string")
    .def("assign", &vector_assign<std::string>)
    .def("__getitem__",+[](const std::vector<std::string> &obj, int i) {return obj.at(i);} );
}

#ifdef MAIN
int main()
{
  aa a;
  vec b {"3","4"};
#if 0
  ab b {"3","4"};
  a.reserve(b.size());
  std::move (b.begin(), b.end(), std::back_inserter(a));
#endif
static_cast<ab&>(a)=std::move(b);
std::cout << b.size()<<"\n";
ab a; a.append("3");
}
#endif
