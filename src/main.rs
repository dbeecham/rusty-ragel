#![no_std]
#![no_main]

extern crate libc;
use libc::{c_int,c_char,printf};


#[repr(C)]
struct NATSParser<'a> {
    cb: extern fn(&'a mut NATSd) -> c_int,
    cs: c_int,
    user_data: &'a mut NATSd
}


#[link(name = "natsparser", kind="static")]
extern "C" {

    fn natsparser_init (
        parser: *mut NATSParser
    ) -> c_int;

    fn natsparser_parse (
        parser: *mut NATSParser,
        string: *const c_char,
        string_len: c_int
    ) -> c_int;

}

enum ParseResult {
    ParseOK,
    ParseError
}

impl<'a> NATSParser<'a> {
    fn new(cb: extern "C" fn(&mut NATSd) -> c_int, natsd: &'a mut NATSd) -> Self {

        let mut parser = NATSParser {
            cb: cb,
            cs: 0,
            user_data: natsd
        };

        unsafe {
            natsparser_init(&mut parser);
        }

        parser
    }

    fn parse(&mut self, string: &'static str) -> ParseResult {
        match unsafe {
            natsparser_parse(self, string.as_ptr() as *const _, string.len() as c_int)
        } {
            -1 => ParseResult::ParseError,
            0 => ParseResult::ParseOK,
            1 => ParseResult::ParseOK,
            _ => ParseResult::ParseError
        }
    }

}

#[repr(C)]
struct NATSd {
    a: i32
}


extern "C" fn mycallback(natsd: &mut NATSd) -> c_int {
    let hello = "Callback called!\n\0";
    (*natsd).a = 0;
    unsafe {
        printf(hello.as_ptr() as *const _);
    }
    0
}


#[no_mangle]
pub extern "C" fn main(_argc: isize, _argv: *const *const u8) -> isize {
    // Since we are passing a C string the final null character is mandatory.
    const HELLO: &'static str = "Hello, world!\n\0";
    unsafe {
        printf(HELLO.as_ptr() as *const _);
    }

    let mut natsd = NATSd {
        a: 3
    };

    let mut parser = NATSParser::new(mycallback, &mut natsd);
    match parser.parse(HELLO) {
        ParseResult::ParseOK => unsafe { printf("Parse ok :)\n\0".as_ptr() as *const _); },
        ParseResult::ParseError => unsafe { printf("Parser error!\n\0".as_ptr() as *const _); },
    }

    0
}

#[panic_handler]
fn my_panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
