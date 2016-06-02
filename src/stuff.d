import std.traits;

version(unittest) import unit_threaded;


struct Maybe(T) {

    alias Wrapped = T;

    static struct Just {
        T value;
    }

    static struct Nothing {}

    static auto return_(T)(T val) {
        return Just(val);
    }
}

auto maybe(T)(T val) {
    return Maybe!T.return_(val);
}

enum isMonad(alias T) = is(typeof(() {
    with(T!int) {
        auto m = return_(0);
        m.bind!(a => a);
    }
}));

enum isMaybe(T) = is(T: Maybe!U.Just, U) || is(T: Maybe!U.Nothing, U);
static assert(isMonad!Maybe);

auto bind(alias F, T)(T monad) if(isMaybe!T) {
    enum isNothing(T) = is(T: Maybe!U.Nothing, U);

    static if(isNothing!T)
        return T();
    else
        return T(F(monad.value));
}


@("Maybe int")
unittest {
    with(Maybe!int) {
        return_(5).bind!(a => a + 1).shouldEqual(maybe(6));
        Nothing().bind!(a => a + 1).shouldEqual(Nothing());
    }
}


@("Maybe string")
unittest {
    with(Maybe!string) {
        return_("foo").bind!(a => a ~ "bar").shouldEqual(return_("foobar"));
        Nothing().bind!(a => a ~ "bar").shouldEqual(Nothing());
    }
}
