package authz

default allow = false

allow if {
    input.method == "GET"
    allowed_roles := {"admin", "developer"}
    allowed_roles[input.user.role]
}
