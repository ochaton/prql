# Design

## Expr

Expr -- any expression

Expr must have public methods:

- `Expr:def(<default-value>) -> expr` - replace NULL with `<default-value>`
- `Expr:isin(r(from, till)) -> expr` - check `in` r - is range
- `Expr:map(<expr>) -> expr` - meaning, that `<expr>` will be applied to `Expr`

- `Expr() -> {schema={}, rows={}}` - when expr is called, execution is started.

## From - from

`from("<source>") | from({ name = "<source>" }) -> expr` - is a method to open `<source>`.
`from("source")([scope]) -> {schema=..., iterator=Iterator<Record>}` - returns fat-iterator with essentials.

From brings scoping into pipeline.

## f("__name__") - name resolver

f("__name__") -> Expr - does scoping
