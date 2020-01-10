use std::fmt;
use std::collections::VecDeque;


#[derive(PartialEq)]
enum Foo<'a> {
    Number(usize),
    String(&'a str),
}

#[derive(PartialEq, Debug)]
enum JuxWord<'a> {
    Number(usize),
    String(&'a str),
    Quotation(VecDeque<JuxWord<'a>>)
}


impl<'a> fmt::Debug for Foo<'a> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            &Foo::Number(num) => write!(f, "{:?}", num),
            &Foo::String(str) => write!(f, "{:?}", str),
        }
    }
}


fn main() {
    let vec = vec![
      Foo::Number(2), 
      Foo::String("hello world"), 
      Foo::String("1000"), 
      Foo::String(":)"),
    ];
    
    for elem in &vec {
        println!("{:?}", elem);
    }
    // let quot: VecDeque<_> = vec![JuxWord::String("Foo")].into_iter().collect();
    
    let vec2 = vec![
        JuxWord::Number(2),
        JuxWord::String("Foobar"),
        JuxWord::Quotation(vec![JuxWord::String("Foo")].into_iter().collect())
    ];
    
    for elem in &vec2 {
        println!("{:?}", elem);
    }
}
