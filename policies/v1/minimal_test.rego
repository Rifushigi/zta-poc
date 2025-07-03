package authz_test

default allow = false

allow if {
    input.token == "test"
}

trace := {
    "input_token": input.token,
    "allow": allow
}
