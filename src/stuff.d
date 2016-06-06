import std.traits;

version(unittest) import unit_threaded;
import std.variant;


struct Maybe(T) {

    private alias SumType = Algebraic!(Just, Nothing);
    private SumType _wrapped;

    private static struct Just {
        T value;
    }

    private static struct Nothing {}

    static auto nothing() {
        return Maybe(SumType(Nothing()));
    }

    static auto return_(T val) {
        return Maybe(SumType(Just(val)));
    }
}

auto just(T)(T val) {
    return Maybe!T.return_(val);
}

enum isMonad(alias T) = is(typeof(() {
    with(T!int) {
        auto m = return_(0);
        m.bind!(a => return_(a));
    }
}));

enum isMaybe(T) = is(T: Maybe!U, U);
static assert(isMonad!Maybe);

T bind(alias F, T)(T monad) if(isMaybe!T) {
    return monad._wrapped.visit!(
        (T.Nothing) => monad,
        (T.Just j) => F(j.value));
}


@("Maybe int")
unittest {
    with(Maybe!int) {
        return_(5).bind!(a => return_(a + 1)).shouldEqual(just(6));
        nothing.bind!(a => return_(a + 1)).shouldEqual(nothing);
        return_(8).bind!(a => nothing).bind!(a => return_(a + 1)).shouldEqual(nothing);
    }
}


@("Maybe string")
unittest {
    with(Maybe!string) {
        return_("foo").bind!(a => return_(a ~ "bar")).shouldEqual(just("foobar"));
        nothing.bind!(a => return_(a ~ "bar")).shouldEqual(nothing);
        return_("foo").bind!(a => return_(a ~ "bar")).bind!(a => nothing).shouldEqual(nothing);
    }
}
