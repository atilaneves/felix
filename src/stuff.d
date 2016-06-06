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

enum isMonad(alias T, U...) = is(typeof(() {
    with(T!(U, int)) {
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

struct Writer(W, T) {
    T value;
    W writee;

    static auto return_(T val) {
        return Writer(val, W.init);
    }

    static assert(isWriter!(Writer!(string, int)));
}

auto writer(T, W)(T t, W w) {
    return Writer!(W, T)(t, w);
}

enum isWriter(T) = is(T: Writer!(W, U), W, U);

T bind(alias F, T)(T monad) if(isWriter!T) {
    auto res = F(monad.value);
    res.writee = monad.writee ~ res.writee;
    return res;
}

static assert(isMonad!(Writer, string));

@("Writer string")
unittest {
    import std.conv: to;
    with(Writer!(string, int)) {
        return_(5).bind!(a => writer(a + 1, "a was " ~ a.to!string)).shouldEqual(writer(6, "a was 5"));
    }
}
