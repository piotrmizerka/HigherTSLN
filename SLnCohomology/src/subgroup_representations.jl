# Computes a flip-permutation representation of a specific subgroup
# of SL(N,p). Available options for (N,p): (3,3) and (4,2).
function flip_permutation_representation(
    n::Integer,
    p::Integer
)
    gens_H, gens_N = symmetric_subgroups_gens(n,p)
    H = keys(subgroup_gens_expression(gens_H, p)) # Express all elements of H as words in the distinguished generators of H.
    N = keys(subgroup_gens_expression(gens_N, p)) # Compute the normal subgroup of H of our interest.
    H_N = SLnCohomology.coset_data(N,H,p)

    subgroup_rep = Dict()
    if n == 3 && p == 3
        for h in H
            subgroup_rep[h] = (h in N ? reshape([1],1,1) : reshape([-1],1,1))
        end
        deg = 1
    elseif n == 4 && p == 2
        elt_coset_labels = H_N["elt_coset_labels"]
        id_ = [1 0 0 0
               0 1 0 0
               0 0 1 0
               0 0 0 1]
        x = [0 1 0 0
             0 1 1 1
             1 1 1 1
             0 0 0 1]
        y = [0 1 0 0
             0 0 0 1
             1 1 0 1
             0 1 1 1]
        x2 = matrix_mod_p(x^2, p)
        yx = matrix_mod_p(y*x, p)
        yx2 = matrix_mod_p(y*x^2, p)
        for h in H
            if elt_coset_labels[h] == elt_coset_labels[id_]
                subgroup_rep[h] = Matrix(Permutations.Permutation([[1],[2],[3]]))
            elseif elt_coset_labels[h] == elt_coset_labels[x]
                subgroup_rep[h] = Matrix(Permutations.Permutation([[1,2,3]]))
            elseif elt_coset_labels[h] == elt_coset_labels[x2]
                subgroup_rep[h] = Matrix(Permutations.Permutation([[3,2,1]]))
            elseif elt_coset_labels[h] == elt_coset_labels[y]
                subgroup_rep[h] = -Matrix(Permutations.Permutation([[1,2],[3]])) 
            elseif elt_coset_labels[h] == elt_coset_labels[yx]    
                subgroup_rep[h] = -Matrix(Permutations.Permutation([[2,3],[1]]))      
            elseif elt_coset_labels[h] == elt_coset_labels[yx2]
                subgroup_rep[h] = -Matrix(Permutations.Permutation([[1,3],[2]]))     
            end
        end
        deg = 3
    end

    # check the homomorphism condition
    for x in H_N["cosets_representatives"]
        for y in H_N["cosets_representatives"]
            @assert subgroup_rep[matrix_mod_p(x*y,p)] == subgroup_rep[x]*subgroup_rep[y]
        end
    end

    return subgroup_rep, deg
end

# Given matrix generators gens_ (assumed to be symmetric in the sense that for all its elements 
# their inverses are also in gens_) of a subgroup H of SL(N,p), express all elements of H as words 
# in gens_ (not necessarily uniquely). Save the output in a dictionary.
# Note that the subgroup H itself and slnp are not arguments of this function.
function subgroup_gens_expression(
    gens_,
    p::Integer
)
    result = Dict(x => [x] for x in gens_)
    I_N = Matrix(UniformScaling(Int8(1)),size(first(gens_))[1],size(first(gens_))[1])
    result[I_N] = []
    while true
        old_result_length = length(result)
        temp_keys = copy(keys(result))
        for M in temp_keys
            for s in gens_
                sM, Ms = matrix_mod_p(s*M,p), matrix_mod_p(M*s,p)
                if !(sM in keys(result))
                    result[sM] = vcat([s],result[M])
                end
                if !(Ms in keys(result))
                    result[Ms] = vcat(result[M],[s])
                end
            end
        end
        if length(result) == old_result_length
            break
        end
    end
    return result
end

# Computes the generators of the subgroup H of SL(n,p) and its index two subgroup K.
function symmetric_subgroups_gens(n::Integer, p::Integer)
    if (n,p) == (3,3)
        # H ≤ SL(3,3) is isomorphic to S₃×S₃. As embedded in SL(3,3), H is generated by:
        s = [0 0 1;
             0 2 0;
             1 1 0]
        t = [1 2 0;
             0 2 0;
             1 1 2]
        s_inv = Int8.(AbstractAlgebra.lift.(inv(AbstractAlgebra.matrix(GF(p),s))))
        gens_H = [s,t,s_inv]

        # Compute index 2 subgroup of H. This subgroup, isomorphic to C₃×S₃ and is generated by:
        a = [0 0 1;
             0 2 0;
             1 1 0]
        b = [0 1 2;
             0 1 0;
             1 2 2]
        c = [1 1 0;
             0 1 0;
             0 2 1]
        a_inv = Int8.(AbstractAlgebra.lift.(inv(AbstractAlgebra.matrix(GF(p),a))))
        b_inv = Int8.(AbstractAlgebra.lift.(inv(AbstractAlgebra.matrix(GF(p),b))))
        c_inv = Int8.(AbstractAlgebra.lift.(inv(AbstractAlgebra.matrix(GF(p),c))))
        gens_N = [a,b,c,a_inv,b_inv,c_inv]
    elseif (n,p) == (4,2)
        # The subgroup H of SL(4,2) we consider is generated by s and t below. H has order 576.
        s = [1 0 0 0;
             0 0 0 1;
             1 1 0 1;
             1 0 1 1]
        t = [0 1 1 0;
             0 1 1 1;
             1 1 1 1;
             0 0 1 1]
        s_inv = Int8.(AbstractAlgebra.lift.(inv(AbstractAlgebra.matrix(GF(p),s))))
        t_inv = Int8.(AbstractAlgebra.lift.(inv(AbstractAlgebra.matrix(GF(p),t))))
        gens_H = [s,t,s_inv,t_inv]

        # Compute index 6 normal subgroup N of H. This subgroup is generated by the following matrices
        # (we also include their inverses in the case they are not idempotent).
        # The quotient H/N is isomorphic to S₃, the symmetric group on three letters.
        a = [1 0 1 1
             0 1 1 1
             0 0 1 0
             0 0 0 1]
        b = [1 1 1 0
             1 0 0 0
             0 0 1 0
             1 0 1 1]
        c = [0 1 1 1
             1 0 1 1
             0 0 1 0
             0 0 0 1]
        d = [1 0 1 0
             0 1 1 0
             0 0 1 0
             0 0 0 1]
        e = [0 1 0 1
             0 1 0 0
             0 0 1 0
             1 1 0 0]
        f = [1 0 0 0
             1 0 1 1
             0 0 1 0
             1 1 1 0]
        b_inv = Int8.(AbstractAlgebra.lift.(inv(AbstractAlgebra.matrix(GF(p),b))))
        gens_N = [a,b,c,d,e,f,b_inv]
    end

    return gens_H, gens_N
end
