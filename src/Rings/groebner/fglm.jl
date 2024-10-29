@doc raw"""
    _fglm(G::IdealGens; ordering::MonomialOrdering)

Converts a Gröbner basis `G` w.r.t. a given global monomial ordering for `<G>`
to a Gröbner basis `H` w.r.t. another monomial ordering `ordering` for `<G>`.

**NOTE**: `_fglm` assumes that `G` is a reduced Gröbner basis (i.e. w.r.t. a global monomial ordering) and that `ordering` is a global monomial ordering.

# Examples
```jldoctest
julia> R, (x1, x2, x3, x4) = polynomial_ring(GF(101), [:x1, :x2, :x3, :x4])
(Multivariate polynomial ring in 4 variables over GF(101), FqMPolyRingElem[x1, x2, x3, x4])

julia> J = ideal(R, [x1+2*x2+2*x3+2*x4-1,
       x1^2+2*x2^2+2*x3^2+2*x4^2-x1,
       2*x1*x2+2*x2*x3+2*x3*x4-x2,
       x2^2+2*x1*x3+2*x2*x4-x3
       ])
Ideal generated by
  x1 + 2*x2 + 2*x3 + 2*x4 + 100
  x1^2 + 100*x1 + 2*x2^2 + 2*x3^2 + 2*x4^2
  2*x1*x2 + 2*x2*x3 + 100*x2 + 2*x3*x4
  2*x1*x3 + x2^2 + 2*x2*x4 + 100*x3

julia> groebner_basis(J, ordering=degrevlex(R), complete_reduction=true)
Gröbner basis with elements
  1: x1 + 2*x2 + 2*x3 + 2*x4 + 100
  2: x3^2 + 2*x2*x4 + 19*x3*x4 + 76*x4^2 + 72*x2 + 86*x3 + 42*x4
  3: x2*x3 + 99*x2*x4 + 40*x3*x4 + 11*x4^2 + 65*x2 + 58*x3 + 30*x4
  4: x2^2 + 2*x2*x4 + 30*x3*x4 + 45*x4^2 + 43*x2 + 72*x3 + 86*x4
  5: x3*x4^2 + 46*x4^3 + 28*x2*x4 + 16*x3*x4 + 7*x4^2 + 58*x2 + 63*x3 + 15*x4
  6: x2*x4^2 + 67*x4^3 + 56*x2*x4 + 58*x3*x4 + 45*x4^2 + 14*x2 + 86*x3
  7: x4^4 + 65*x4^3 + 26*x2*x4 + 47*x3*x4 + 71*x4^2 + 37*x2 + 79*x3 + 100*x4
with respect to the ordering
  degrevlex([x1, x2, x3, x4])

julia> Oscar._fglm(J.gb[degrevlex(R)], lex(R))
Gröbner basis with elements
  1: x4^8 + 36*x4^7 + 95*x4^6 + 39*x4^5 + 74*x4^4 + 7*x4^3 + 45*x4^2 + 98*x4
  2: x3 + 53*x4^7 + 93*x4^6 + 74*x4^5 + 26*x4^4 + 56*x4^3 + 15*x4^2 + 88*x4
  3: x2 + 25*x4^7 + 57*x4^6 + 13*x4^5 + 16*x4^4 + 78*x4^3 + 31*x4^2 + 16*x4
  4: x1 + 46*x4^7 + 3*x4^6 + 28*x4^5 + 17*x4^4 + 35*x4^3 + 9*x4^2 + 97*x4 + 100
with respect to the ordering
  lex([x1, x2, x3, x4])
```
"""
function _fglm(G::IdealGens, ordering::MonomialOrdering)
  (G.isGB == true && G.isReduced == true) || error("Input must be a reduced Gröbner basis.") 
  Singular.dimension(singular_generators(G)) == 0 || error("Dimension of corresponding ideal must be zero.")
  SR_destination, = Singular.polynomial_ring(base_ring(G.Sx), symbols(G.Sx); ordering = singular(ordering))

  ptr = Singular.libSingular.fglmzero(G.S.ptr, G.Sx.ptr, SR_destination.ptr)
  return IdealGens(base_ring(G), Singular.sideal{Singular.spoly}(SR_destination, ptr, true))
end

@doc raw"""
    fglm(I::MPolyIdeal; start_ordering::MonomialOrdering = default_ordering(base_ring(I)),
                        destination_ordering::MonomialOrdering)

Given a **zero-dimensional** ideal `I`, return the reduced Gröbner basis of `I` with respect to `destination_ordering`.

!!! note
    Both `start_ordering` and `destination_ordering` must be global and the base ring of `I` must be a polynomial ring over a field.

!!! note
    The function implements the Gröbner basis conversion algorithm by **F**augère, **G**ianni, **L**azard, and **M**ora. See [FGLM93](@cite) for more information.

# Examples
```jldoctest
julia> R, (a, b, c, d, e) = polynomial_ring(QQ, [:a, :b, :c, :d, :e]);

julia> f1 = a+b+c+d+e;

julia> f2 = a*b+b*c+c*d+a*e+d*e;

julia> f3 = a*b*c+b*c*d+a*b*e+a*d*e+c*d*e;

julia> f4 = b*c*d+a*b*c*e+a*b*d*e+a*c*d*e+b*c*d*e;

julia> f5 = a*b*c*d*e-1;

julia> I = ideal(R, [f1, f2, f3, f4, f5]);

julia> G = fglm(I, destination_ordering = lex(R));

julia> length(G)
8

julia> total_degree(G[8])
60

julia> leading_coefficient(G[8])
83369589588385815165248207597941242098312973356252482872580035860533111990678631297423089011608753348453253671406641805924218003925165995322989635503951507226650115539638517111445927746874479234
```
"""
function fglm(I::MPolyIdeal; start_ordering::MonomialOrdering = default_ordering(base_ring(I)), destination_ordering::MonomialOrdering)
  isa(coefficient_ring(I), AbstractAlgebra.Field) || error("The FGLM algorithm requires a coefficient ring that is a field.")
  (is_global(start_ordering) && is_global(destination_ordering)) || error("Start and destination orderings must be global.")
  haskey(I.gb, destination_ordering) && return I.gb[destination_ordering]
  if !haskey(I.gb, start_ordering)
    standard_basis(I, ordering=start_ordering, complete_reduction=true)
  elseif I.gb[start_ordering].isReduced == false
    I.gb[start_ordering] = _compute_standard_basis(I.gb[start_ordering], start_ordering, true)
  end

  I.gb[destination_ordering] = _fglm(I.gb[start_ordering], destination_ordering)

  return I.gb[destination_ordering]
end

@doc raw"""
    _compute_groebner_basis_using_fglm(I::MPolyIdeal, destination_ordering::MonomialOrdering)

Computes a reduced Gröbner basis for `I` w.r.t. `destination_ordering` using the FGLM algorithm.

**Note**: Internal function, subject to change, do not use.

# Examples
```jldoctest
julia> R, (x, y) = polynomial_ring(QQ, [:x, :y])
(Multivariate polynomial ring in 2 variables over QQ, QQMPolyRingElem[x, y])

julia> I = ideal(R,[x^2+y,x*y-y])
Ideal generated by
  x^2 + y
  x*y - y

julia> Oscar._compute_groebner_basis_using_fglm(I, lex(R))
Gröbner basis with elements
  1: y^2 + y
  2: x*y - y
  3: x^2 + y
with respect to the ordering
  lex([x, y])

julia> I.gb[lex(R)]
Gröbner basis with elements
  1: y^2 + y
  2: x*y - y
  3: x^2 + y
with respect to the ordering
  lex([x, y])

julia> I.gb[degrevlex(R)]
Gröbner basis with elements
  1: y^2 + y
  2: x*y - y
  3: x^2 + y
with respect to the ordering
  degrevlex([x, y])
```
"""
function _compute_groebner_basis_using_fglm(I::MPolyIdeal,
  destination_ordering::MonomialOrdering)
  isa(coefficient_ring(I), AbstractAlgebra.Field) || error("The FGLM algorithm requires a coefficient ring that is a field.")
  haskey(I.gb, destination_ordering) && return I.gb[destination_ordering]
  is_global(destination_ordering) || error("Destination ordering must be global.")
  G = groebner_assure(I, true, true)
  start_ordering = G.ord
  dim(I) == 0 || error("Dimension of ideal must be zero.")
  I.gb[destination_ordering] = _fglm(G, destination_ordering)
end
