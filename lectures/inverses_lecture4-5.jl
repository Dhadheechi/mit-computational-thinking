### A Pluto.jl notebook ###
# v0.20.4

#> [frontmatter]
#> chapter = 1
#> video = "https://www.youtube.com/watch?v=VDPf3RjoCpY"
#> image = "https://user-images.githubusercontent.com/6933510/136196619-0750544f-cd6d-4ae3-ace7-60c24443d721.png"
#> section = 5
#> order = 5
#> title = "Transformations II: Composability, Linearity and Nonlinearity"
#> layout = "layout.jlhtml"
#> youtube_id = "VDPf3RjoCpY"
#> description = "Let's see what mathematical transformations, inverses, composition and (non-)linearity look like in practice. (i.e. applied to philip.jpg)"
#> tags = ["lecture", "module1", "transformation", "track_math", "track_julia", "inverse", "composition", "matrix", "linear algebra", "nonlinear", "linear"]

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 6b473b2d-4326-46b4-af38-07b61de287fc
begin
	using PlutoUI 
	using Colors, ColorVectorSpace, ImageShow, FileIO, ImageIO
	using PlutoUI
	using LinearAlgebra
	using ForwardDiff
	using NonlinearSolve
	using StaticArrays
end

# ╔═╡ b7895bd2-7634-11eb-211e-ef876d23bd88
PlutoUI.TableOfContents(aside=true)

# ╔═╡ 230b0118-30b7-4035-ad31-520165a76fcc
md"""
#### Initializing packages

_When running this notebook for the first time, this could take up to 15 minutes. Hang in there!_
"""

# ╔═╡ 890d30b9-2cd0-4d3a-99f6-f7d3d7858fda
urls = (
	corgis = "https://user-images.githubusercontent.com/6933510/108605549-fb28e180-73b4-11eb-8520-7e29db0cc965.png",
	longcorgi = "https://user-images.githubusercontent.com/6933510/110868198-713faa80-82c8-11eb-8264-d69df4509f49.png",
	theteam = "https://news.mit.edu/sites/default/files/styles/news_article__image_gallery/public/images/202004/edelman%2520philip%2520sanders.png?itok=ZcYu9NFeg",
)

# ╔═╡ bb149122-7f62-4b60-a9fd-4455ff02fa9d


# ╔═╡ 96766502-7a06-11eb-00cc-29849773dbcf
img_original = load(download(urls.longcorgi));

# ╔═╡ d495e48b-99d2-45b0-b40f-09f57643dfd5
img_original

# ╔═╡ e0b657ce-7a03-11eb-1f9d-f32168cb5394
md"""
#  The fun stuff: playing with transforms
"""

# ╔═╡ 005ca75a-7622-11eb-2ba4-9f450e71df1f
let

range = -1.5:.1:1.5
md"""
	
This is a "scrubbable" matrix: click on the number and drag to change!
	
**A =**  
	
``(``	
 $(@bind a Scrubbable( range; default=1.0))
 $(@bind b Scrubbable( range; default=0.0))
``)``

``(``
$(@bind c Scrubbable(range; default=0.0 ))
$(@bind d Scrubbable(range; default=1.0)) 
``)``  
	

	
"""
end

# ╔═╡ 23ade8ee-7a09-11eb-0e40-296c6b831d74
md"""
Grab a [linear](#a0afe3ae-76b9-11eb-2301-cde7260ddd7f) or [nonlinear](#a290d5e2-7a02-11eb-37db-41bf86b1f3b3) transform, or make up your own!
"""

# ╔═╡ 2efaa336-7630-11eb-0c17-a7d4a0141dac
md"""
zoom = $(@bind  z Scrubbable(.1:.1:3,  default=1))
"""

# ╔═╡ 7f28ac40-7914-11eb-1403-b7bec34aeb94
md"""
pan = [$(@bind panx Scrubbable(-1:.1:1, default=0)), 
$(@bind pany Scrubbable(-1:.1:1, default=0)) ]
"""

# ╔═╡ b76a5bd6-802f-11eb-0951-1f1092dee8de
1+1

# ╔═╡ 5d33f6ea-7e9c-11eb-2fb3-dbb7cb07c60c
md"""
pixels = $(@bind pixels Slider(1:1000, default=800, show_value=true))
"""

# ╔═╡ 45dccdec-7912-11eb-01b4-a97e30344f39
md"""
Show grid lines $(@bind show_grid CheckBox(default=true))
ngrid = $(@bind ngrid Slider(5:5:20, show_value=true, default = 10))
"""

# ╔═╡ d2fb356e-7f32-11eb-177d-4f47d6c9e59b
md"""
Circular Frame $(@bind circular CheckBox(default=true))
radius = $(@bind r Slider(.1:.1:1, show_value=true, default = 1))
"""

# ╔═╡ ce55beee-7643-11eb-04bc-b517703facff
md"""
α= $(@bind α Slider(-30:.1:30, show_value=true, default=0))
β= $(@bind β Slider(-10:.1:10, show_value=true, default = 5))
h= $(@bind h Slider(.1:.1:10, show_value=true, default = 5))
"""

# ╔═╡ 4fe8f309-9d9a-495e-a768-c7771bcc654d
# # Forward mapping approach
# let
#     # Create a blank output image of the same size as the destination
#     output_img = zeros(pixels, pixels)
    
#     # Iterate through each pixel in the SOURCE image
#     for i = 1:size(img, 1), j = 1:size(img, 2)
#         # Get the source color
#         source_color = getpixel(img, i, j)
        
#         # Convert source coordinates to (x,y) normalized space
#         x, y = transform_ij_to_xy(i, j, size(img))
        
#         # Apply the transformation T (not T⁻¹) to get destination coordinates
#         X, Y = (scale(z) ∘ translate(panx, pany))([x, y])
        
#         # Convert back to pixel coordinates in the output space
#         dest_i, dest_j = transform_xy_to_ij(pixels, X, Y)
        
#         # Round to nearest integer since we need discrete pixel locations
#         dest_i, dest_j = round(Int, dest_i), round(Int, dest_j)
        
#         # Check if the destination coordinates are within bounds
#         if 1 <= dest_i <= pixels && 1 <= dest_j <= pixels
#             # Set the pixel in the output image
#             output_img[dest_i, dest_j] = source_color
#         end
#     end
    
#     # At this point, output_img may have holes (pixels that weren't assigned a value)
    
#     # Return the output image
#     output_img
# end

# ╔═╡ 55b5fc92-7a76-11eb-3fba-854c65eb87f9
md"""
Above: The original image is placed in a [-1,1] x [-1 1] box and transformed.
"""

# ╔═╡ 85686412-7a75-11eb-3d83-9f2f8a3c5509
A = [a b ; c d];

# ╔═╡ a7df7346-79f8-11eb-1de6-71f027c46643
md"""
## Pedagogical note: Why the Module 1 application = image processing

Image processing is a great way to learn Julia, some linear algebra, and some nonlinear mathematics.  We don't presume the audience will become professional image processors, but we do believe that the principles learned transcend so many applications... and everybody loves playing with their own images!  
"""

# ╔═╡ 044e6128-79fe-11eb-18c1-395ae857dc73
md"""
# Last Lecture Leftovers
"""

# ╔═╡ 78d61e28-79f9-11eb-0605-e77d206cda84
md"""
## Interesting question about linear transformations
If a transformation takes lines into lines and preserves the origin, does it have to be linear?

Answer = **no**!

The example of a **perspective map** takes all lines into lines, but parallelograms generally do not become parallelograms. 
"""

# ╔═╡ aad4d6e4-79f9-11eb-0342-b900a41cfbaf
md"""
[A nice interactive demo of perspective maps](https://www.khanacademy.org/humanities/renaissance-reformation/early-renaissance1/beginners-renaissance-florence/a/linear-perspective-interactive) from Khan academy.
"""

# ╔═╡ d42aec08-76ad-11eb-361a-a1f2c90fd4ec
Resource("https://cdn.kastatic.org/ka-perseus-images/1b351a3653c1a12f713ec24f443a95516f916136.jpg")

# ╔═╡ d9115c1a-7aa0-11eb-38e4-d977c5a6b75b
md"""
**Challenge exercise**: Rewrite this using Julia and Pluto!
"""

# ╔═╡ e965cf5e-79fd-11eb-201d-695b54d08e54
md"""
## Julia style (a little advanced): Reminder about defining vector valued functions
"""

# ╔═╡ 1e11c1ec-79fe-11eb-1867-9da72b3f3bc4
md"""
Many people find it hard to read 


```julia
f(v) = [ v[1]+v[2] , v[1]-v[2] ]

# or

f = v ->  [ v[1]+v[2] , v[1]-v[2] ]
```

and instead prefer

```julia
f((x,y)) = [ x+y , x-y ]

# or

f = ((x,y),) -> [ x+y , x-y ]
```

All four of these will take a 2-vector to a 2-vector in the same way for the purposes of this lecture, i.e. `f( [1,2] )` can be defined by any of the four forms.

The forms with the `->` are anonymous functions.  (They are still
considered anonymous, even though we then name them `f`.)
"""

# ╔═╡ 28ef451c-7aa1-11eb-340c-ab3a1193a3c4
md"""
## Functions with parameters
The anonymous form comes in handy when one wants a function to depend on a **parameter**.
For example:

`f(α) = ((x,y),) -> [x + αy, x - αy]`

allows you to apply the `f(7)` function to the input vector `[1, 2]` by running
`f(7)([1, 2])` .
"""

# ╔═╡ a0afe3ae-76b9-11eb-2301-cde7260ddd7f
md"""
# Linear transformations: a collection
"""

# ╔═╡ fc2deb7c-7aa1-11eb-019f-d3e3c80b9ff1
md"""
Here are a few useful linear transformations:
"""

# ╔═╡ d364f91a-76b9-11eb-1807-75e733940d53
begin
	 id((x, y)) = SA[x, y]
	
	 scalex(α) = ((x, y),) -> SA[α*x,  y]
	 scaley(α) = ((x, y),) -> SA[x,   α*y]
	 scale(α)  = ((x, y),) -> SA[α*x, α*y]
	
	 swap((x, y))  = SA[y, x]
	 flipy((x, y)) = SA[x, -y]
	
	 rotate(θ) = ((x, y),) -> SA[cos(θ)*x + sin(θ)*y, -sin(θ)*x + cos(θ)*y]
	 shear(α)  = ((x, y),) -> SA[x + α*y, y]
end

# ╔═╡ 080d87e0-7aa2-11eb-18f5-2fb6a7a5bcb4
md"""
In fact we can write down the *most general* linear transformation in one of two ways:
"""

# ╔═╡ 15283aba-7aa2-11eb-389c-e9f215bd03e2
begin
	lin(a, b, c, d) = ((x, y),) -> (a*x + b*y, c*x + d*y)
	
	lin(A) = v-> A * [v...]  # linear algebra version using matrix multiplication
end

# ╔═╡ b77afa13-8754-40c5-947d-b9c3badefcf6
((5,2))

# ╔═╡ 2612d2c2-7aa2-11eb-085a-1f27b6174995
md"""
The second version uses the matrix multiplication notation from linear algebra, which means exactly the same as the first version when 

$$A = \begin{bmatrix} a & b \\ c & d \end{bmatrix}$$
"""

# ╔═╡ a290d5e2-7a02-11eb-37db-41bf86b1f3b3
md"""
# Nonlinear transformations: a collection
"""

# ╔═╡ 50d80844-e8bb-4c84-9bc2-15f547f0e3a9
translate(α,β)  = ((x, y),) -> SA[x+α, y+β];   # affine, but not linear

# ╔═╡ 5677b510-bd37-4e6c-b20c-0a9d578e3ed0
nonlin_shear(α) = ((x, y),) -> SA[x, y + α*x^2];

# ╔═╡ 58a30e54-7a08-11eb-1c57-dfef0000255f
# T⁻¹ = id
#  T⁻¹ = rotate(α)
  # T⁻¹ = shear(α)
#   T⁻¹ = lin(A) # uses the scrubbable 
  # T⁻¹ = shear(α) ∘ shear(-α) # these operations are inverses of each other
 # T⁻¹ = nonlin_shear(α)  
   # T⁻¹ =   inverse(nonlin_shear(α))
   T⁻¹ =  nonlin_shear(-α)
 # T⁻¹ =  xy 
 # T⁻¹ =  rθ 
 # T⁻¹ =  xy ∘ rθ
# T⁻¹ = warp(α)
# T⁻¹ = ((x,y),)-> (x+α*y^2,y+α*x^2) # may be non-invertible

# T⁻¹ = ((x,y),)-> (x,y^2)  
# T⁻¹  = flipy ∘ ((x,y),) ->  ( (β*x - α*y)/(β - y)  , -h*y/ (β - y)   ) 

# ╔═╡ 09e961c1-4e25-4589-ad17-04d747053475
warp(α)    = ((x, y),) -> rotate(α*√(x^2+y^2))(SA[x, y]);

# ╔═╡ a591552b-d0dd-49a5-ad08-7b59d4e0b34d
xy((r, θ)) = SA[ r*cos(θ), r*sin(θ) ];

# ╔═╡ 58e5bc84-50ad-4ecc-a191-7ccf3fa3a1fd
rθ(x)      = SA[norm(x), atan(x[2],x[1]) ];

# ╔═╡ 4b097c6e-e22c-451f-acb6-bfbfe9a0110f
# exponentialish =  ((x,y),) -> [log(x+1.2), log(y+1.2)];

# ╔═╡ a8577554-7997-4f35-bfa2-26f1b58813e4
# merc = ((x,y),) ->  [ log(x^2+y^2)/2 , atan(y,x) ]; # (reim(log(complex(y,x)) ))

# ╔═╡ 704a87ec-7a1e-11eb-3964-e102357a4d1f
md"""
# Composition
"""

# ╔═╡ 4b0e8742-7a70-11eb-1e78-813f6ad005f4
let
	x = rand()

	# these two are the same!
	a = ( sin ∘ cos )(x)
	b = sin(cos(x))
	
	a == b
end

# ╔═╡ 44792484-7a20-11eb-1c09-95b27b08bd34
md"""
## Composing functions in mathematics
[Wikipedia (math) ](https://en.wikipedia.org/wiki/Function_composition)

In math we talk about *composing* two functions to create a new function:
the function that takes $x$ to $\sin(\cos(x))$ is the **composition**
of the sine function and the cosine function.  

We humans tend to blur the distinction between the sine function
and the value of $\sin(x)$ at some point $x$.  The sine function
is a mathematical object by itself.  It's a thing that can be evaluated
at as many $x$'s as you like.  

If you look at the two sides of
` (sin ∘ cos )(x) ≈ sin(cos(x)) ` and see that they are exactly the same, it's time to ask yourself what's a key difference? On the left a function is built
` sin ∘ cos ` which is then evaluated at `x`.  On the right, that function
is never built.
"""



# ╔═╡ f650b788-7a70-11eb-0b20-779d2f18f111
md"""
## Composing functions in computer science
[wikipedia (cs)](https://en.wikipedia.org/wiki/Function_composition_(computer_science))

A key issue is a programming language is whether it's easy to name
the composition in that language.  In Julia one can create the function
`sin ∘ cos`  and one can readily check that ` (sin ∘ cos)(x) ` always yields the same value as `sin(cos(x))`.
"""

# ╔═╡ c852d398-7aa2-11eb-2ded-ab2e5236e9b2
md"""

## Composing functions in Julia
[Julia's  `∘` operator](https://docs.julialang.org/en/v1/manual/functions/#Function-composition-and-piping) 
follows the [mathematical typography](https://en.wikipedia.org/wiki/Function_composition#Typography) convention, as was
shown in the `sin ∘ cos` example above. We can type this symbol as `\circ<TAB>`.

"""

# ╔═╡ 061076c2-7aa3-11eb-0d04-b7cbc60e6cb2
md"""
## Composition of software at a higher level

The trend these days is to have higher-order composition of functionalities.
A good example would be that an optimization can wrap a highly complicated
program which might include all kinds of solvers, and still run successfully.
This might require the ability of the outer software to have some awareness
of the inner software.  It can be quite magical when two very different pieces of software "compose", i.e. work together.  Julia's language construction encourages composability.  We will discuss this more in a future lecture.

"""

# ╔═╡ 014c14a6-7a72-11eb-119b-f5cfc82085ca
md"""
### Find your own examples

Take some of the Linear and Nonlinear Transformations (see the Table of Contents) and find some inverses by placing them in the `T=` section of "The fun stuff" at the top of this notebook.
"""

# ╔═╡ 89f0bc54-76bb-11eb-271b-3190b4d8cbc0
md"""
Linear transformations can be written in math using matrix multiplication notation as 

$$\begin{pmatrix} a & b \\ c & d \end{pmatrix}
\begin{pmatrix} x \\ y \end{pmatrix}$$.
"""

# ╔═╡ f70f7ea8-76b9-11eb-3bd7-87d40a2861b1
md"""
By contrast, here are a few fun functions that cannot be written as matrix times
vector.  What characterizes the matrix ones from the non-matrix ones?
"""

# ╔═╡ bf28c388-76bd-11eb-08a7-af2671218017
md"""
This may be a little fancy, but we see that warp is a rotation, but the
rotation depends on the point where it is applied.
"""

# ╔═╡ 5655d2a6-76bd-11eb-3042-5b2dd3f6f44e
begin	
	warp₂(α,x,y) = rotate(α*√(x^2+y^2))
	warp₂(α) = ((x, y),) -> warp₂(α,x,y)([x,y])	
end

# ╔═╡ 56f1e4cc-7a03-11eb-187b-c5a917978eb9
warp3(α) = ((x, y),) -> rotate(α*√(x^2+y^2))([x,y])

# ╔═╡ 70dc4346-7a03-11eb-055e-111d2519a44c
warp3(1)([1,2])

# ╔═╡ 852592d6-76bd-11eb-1265-5f200e39113d
warp(1)([5,6])

# ╔═╡ 8e36f4a2-76bd-11eb-2fda-9d1424752812
warp₂(1.0)([5.0,6.0])

# ╔═╡ a8bf7128-7aa5-11eb-3ee9-953b0b5ccd01


# ╔═╡ ad700740-7a74-11eb-3369-15e5fd89194d
md"""
# Linear transformations: See a matrix, think beyond number arrays
"""

# ╔═╡ e051259a-7a74-11eb-12fc-99c5dc867fbd
md"""
Software writers and beginning linear algebra students see a matrix and see a lowly table of numbers.  We want you to see a *linear transformation* -- that's what professional mathematicians see.
"""

# ╔═╡ 1856ddae-7a78-11eb-3422-298e1103275b
md"""
What defines a linear transformation?  There are a few equivalent ways of giving a definition.
"""

# ╔═╡ 4b4fe818-7a78-11eb-2986-59e60063d346
md"""
## Linear transformation definitions:
"""

# ╔═╡ 5d656494-7a78-11eb-12e8-d17856bd8c4d
md"""
> ### The intuitive definition:
> 
> The rectangles (gridlines) in the transformed image [above](#e0b657ce-7a03-11eb-1f9d-f32168cb5394) always become a lattice of congruent parallelograms.

> ### The easy operational (but devoid of intuition) definition: 
> 
> A transformation is linear if it is defined by $v \mapsto A*v$ (matrix times vector) for some fixed matrix $A$.

> ### The scaling and adding definition:
> 
> 1. If you scale and then transform or if you transform and then scale, the result is always the same:
>
> $T(cv)=c \, T(v)$ ( $v$ is any vector, and $c$ any number.)
>
> 2. If you add and then transform or vice versa the result is the same:
>
> $T(v_1+v_2) = T(v_1) + T(v_2).$ ($v_1,v_2$ are any vectors.)

> ### The mathematician's definition:
> 
> (A consolidation of the above definition.) $T$ is linear if
>
> $T(c_1 v_1 + c_2 v_2) = c_1 T(v_1) + c_2 T(v_2)$ for all numbers $c_1,c_2$ and vectors $v_1,v_2$.  (This can be extended to beyond 2 terms.)

"""

# ╔═╡ b0e6d1ac-7a7d-11eb-0a9e-1310dcb5957f
md"""
## The *Matrix*
"""

# ╔═╡ 7e4ad37c-7a84-11eb-1490-25090e133a7c
Resource("https://upload.wikimedia.org/wikipedia/en/c/c1/The_Matrix_Poster.jpg")

# ╔═╡ 96f47252-7a84-11eb-3d18-e3ba79dd20c2
md"""
*No, not that matrix!*
"""

# ╔═╡ ae5b3a32-7a84-11eb-04c0-337a74105a58
md"""
The matrix for a linear transformation $T$ is easy to write down: The first
column is $T([1, 0])$ and the second is $T([0,1])$. That's it!
"""

# ╔═╡ c9f2b61e-7a84-11eb-3841-33739a226ff9
md"""
Once we have those, the linearity relation

$$T([x,y]) = x \, T([1,0]) + y \, T([0,1]) = x \, \mathrm{(column\ 1)} + y \, \mathrm{(column\ 2)}$$

is exactly the definition of matrix times vector. Try it.
"""

# ╔═╡ 23d8a45c-7a85-11eb-3a68-ef11e6f58cac
md"""
### Matrix multiply:  You know how to do it, but  why?
"""

# ╔═╡ 4a96d516-7a85-11eb-181c-63a6b461790b
md"""
Did you ever ask yourself why matrix multiply has that somewhat complicated multiplying and adding going on?
"""

# ╔═╡ 8206e1ee-7a8a-11eb-1f26-054f6b100076
let
	 A = randn(2,2)
	 B = randn(2,2)
	 v = rand(2)
	
	(lin(A) ∘ lin(B))(v), lin(A * B)(v)
end

# ╔═╡ 7d803684-7a8a-11eb-33d2-89d5e2a05bcf
md"""
**Important:** The composition of the linear transformation is the linear transformation of the multiplied matrices!  There is only one definition of
matmul (matrix multiply) that realizes this fact.  

To see what it is exactly, remember the first column of `lin(A) ∘ lin(B)` should
be the result of computing the two matrix times vectors  $y=A*[1,0]$ then $z=A*y$,
and the second column is the same for $[0,1]$.

This is worth writing out if you have never done this.
"""

# ╔═╡ 17281256-7aa5-11eb-3144-b72777334326
md"""
Let's try doing that with random matrices:
"""

# ╔═╡ 05049fa0-7a8e-11eb-283b-cb4753c4aaf0
begin
	 
	P = randn(2, 2)
	Q = randn(2, 2)
	
	
	T₁ = lin(P) ∘ lin(Q)
	T₂ = lin(P*Q)
	
	lin(P*Q)((1, 0)), (lin(P)∘lin(Q))((1, 0))
end

# ╔═╡ 350f40f7-795f-4f33-89b8-ff9ba4819e1c
test_img = load(download(urls.corgis));

# ╔═╡ 313cdcbd-5b11-41c8-9fcd-5aeaca3b8d24
test_pixels = 300;

# ╔═╡ 57848b42-7a8f-11eb-023a-cf247cb53819
md"""
`lin(P*Q)`
"""

# ╔═╡ 620ee7d8-7a8f-11eb-3888-356c27a2d591
md"""
`lin(P)∘lin(Q)`
"""

# ╔═╡ 04da7710-7a91-11eb-02a1-0b6e889150a2
md"""
# Coordinate transformations vs object transformations
"""

# ╔═╡ 155cd218-7a91-11eb-0b4c-bd028507e925
md"""
If you want to move an object to the right, the first thing you might think of is adding 1 to the $x$ coordinate of every point.  The other thing you could do is to subtract one from the first coordinate of the coordinate system.  The latter is an example of a coordinate transform.
"""

# ╔═╡ fd25da12-7a92-11eb-20c0-995e7c46b3bc
md"""
### Coordinate transform of an array $(i, j)$ vs points $(x, y)$
"""

# ╔═╡ 1ab2265e-7c1d-11eb-26df-39c4c7289243
md"""
The original image has (1,1) in the upper left corner as an array but is thought
of as existing in the entire plane.
"""

# ╔═╡ c1efc54a-7e9b-11eb-1e76-dbd0a66184a9
translate(-400,400)([1,1])

# ╔═╡ db4bc328-76bb-11eb-28dc-eb9df8892d01
md"""
# Inverses
"""

# ╔═╡ 0b8ed36c-7a1e-11eb-053c-63cf9ee0b16f
md"""
If $f$ is a function from 2-vectors to 2-vectors (say), we define the **inverse** of $f$, denoted
$f^{-1}$, to have the property that it "*undoes*" the effect of $f$, i.e.

$$f(f^{-1}(v))=v$$ 

and $f^{-1}(f(v))=v$.

This equation might be true for all $v$ or for some $v$ in a region.   
"""

# ╔═╡ 7a4e785e-7a71-11eb-07fb-cfba453a117b
md"""
## Example: Scaling up and down
"""

# ╔═╡ 9264508a-7a71-11eb-1b7c-bf6e62788115
let
	v = rand(2)
	T = rotate(30)∘rotate(-30)
	T(v),  v 
end

# ╔═╡ e89339b2-7a71-11eb-0f97-971b2ed277d1
let	
	  T = scale(0.5) ∘ scale(2)
	
	  v = rand(2)
	  T(v) .≈ v 
end

# ╔═╡ 0957fd9a-7a72-11eb-0566-e93ef32fb626
md"""
We observe numerically that `scale(2)` and `scale(.5)` are mutually inverse transformations, i.e. each is the inverse of the other.
"""

# ╔═╡ c7cc412c-7aa5-11eb-2df1-d3d788047238
md"""
## Inverses: Solving equations
"""

# ╔═╡ ce620b8e-7aa5-11eb-370b-11e34b07d54d
md"""
What does an inverse really do?

Let's think about scaling again.
Suppose we scale an input vector $\mathbf{x}$ by 2 to get an output vector $\mathbf{x}$:

$$\mathbf{y} = 2 \mathbf{x}$$

Now suppose that you want to go backwards. If you are given $\mathbf{y}$, how do you find $\mathbf{x}$? In this particular case we see that $\mathbf{x} = \frac{1}{2} \mathbf{y}$.

If we have a *linear* transformation, we can write

$$\mathbf{y} = A \, \mathbf{x}$$

with a matrix $A$. 

If we are given $\mathbf{y}$ and want to go backwards to find the $\mathbf{x}$ from that, we need to *solve a system of linear equations*.


*Usually*, but *not always*, we can solve these equations to find a new matrix $B$ such that

$$\mathbf{x} = B \, \mathbf{y},$$

i.e. $B$ *undoes* the effect of $A$. Then we have


$$\mathbf{x} = (B \, A) * \mathbf{x},$$

so that $B * A$ must be the identity matrix. We call $B$ the *matrix inverse* of $A$, and write

$$B = A^{-1}.$$

For $2 \times 2$ matrices we can write down an explicit formula for the matrix inverse, but in general we will need a computer to run an algorithm to find the inverse.


"""

# ╔═╡ 4f51931c-7aac-11eb-13ba-4b8768ac376f
md"""
### Inverting Linear Transformations
"""

# ╔═╡ 5ce799f4-7aac-11eb-0629-ebd8a404e9d3
let
	v = rand(2)
	A = randn(2,2)
    (lin(inv(A)) ∘ lin(A))(v), v
end 

# ╔═╡ 9b456686-7aac-11eb-3aa5-25e6c3c86aff
let 
	 A = randn(2,2)
	 B = randn(2,2)
	 inv(A*B) ≈ inv(B) * inv(A)
end

# ╔═╡ c2b0a488-7aac-11eb-1d8b-edd6bd23d1fd
md"""
``A^{-1}
=
\begin{pmatrix} d & -b \\ -c & a  \end{pmatrix} / (ad-bc) \quad
``
if
``\ A \ =
\begin{pmatrix} a & b \\ c & d  \end{pmatrix} .
``
"""

# ╔═╡ 02d6b440-7aa7-11eb-1be0-b78dea91387f
md"""
### Inverting nonlinear transformations
"""

# ╔═╡ 0be9fb1e-7aa7-11eb-0116-c3e86ab82c77
md"""
What about if we have a *nonlinear* transformation $T$ -- can we invert it? In other words, if $\mathbf{y} = T(\mathbf{x})$, can we solve this to find $\mathbf{x}$ in terms of $\mathbf{y}$? 


In general this is a difficult question! Sometimes we can do so analytically, but usually we cannot.

Nonetheless, there are *numerical* methods that can sometimes solve these equations, for example the [Newton method](https://en.wikipedia.org/wiki/Newton%27s_method).

There are several implementations of such methods in Julia, e.g. in the [NonlinearSolve.jl package](https://github.com/JuliaComputing/NonlinearSolve.jl). We have used that to write a function `inverse` that tries to invert nonlinear transformations of our images.
"""

# ╔═╡ 7609d686-7aa7-11eb-310a-3550509504a1
md"""
# The Big Diagram of Transforming Images
"""

# ╔═╡ 1b9faf64-7aab-11eb-1396-6fb89be7c445
Resource("https://raw.githubusercontent.com/mitmath/18S191/Spring21/notebooks/week3/comm2.png")

# ╔═╡ 5f0568dc-7aad-11eb-162f-0d6e26f17d59
md"""
Note that we are defining the map with the inverse of T so we can go pixel by pixel in the result.
"""

# ╔═╡ 8d32fff4-7c1b-11eb-1fa1-6ff2d87bfb73
md"""
## Collisions
"""

# ╔═╡ 62a9201c-7938-11eb-144c-15690c06be94
begin
	function inverse(f, y, u0=@SVector[0.0, 0.0])
	    prob = NonlinearProblem{false}( (u, p) -> f(u, p) .- y, u0)
	    solver = solve(prob, NewtonRaphson(), tol = 1e-4)
	    return solver.u 
	end
	
	inverse(f) = y -> inverse( (u, p) -> f(SVector(u...)), y )
end

# ╔═╡ 5227afd0-7641-11eb-0065-918cb8538d55
md"""


Check out
[Linear Map Wikipedia](https://en.wikipedia.org/wiki/Linear_map)

[Transformation Matrix Wikipedia](https://en.wikipedia.org/wiki/Transformation_matrix)
"""

# ╔═╡ 4c93d784-763d-11eb-1f48-81d4d45d5ce0
md"""
## Why are we doing this backwards?

If one moves the colors forward rather than backwards you have trouble dealing
with the discrete pixels.  You may have gaps.  You may have multiple colors going
to the same pixel.

An interpolation scheme or a newton scheme could work for going forwards, but very likely care would be neeeded for a satisfying general result.
"""

# ╔═╡ c536dafb-4206-4689-ad6d-6935385d8fdf
md"""
# Appendix
"""

# ╔═╡ fb509fb4-9608-421d-9c40-a4375f459b3f
det_A = det(A)

# ╔═╡ b754bae2-762f-11eb-1c6a-01251495a9bb
begin
	white(c::RGB) = RGB(1,1,1)
	white(c::RGBA) = RGBA(1,1,1,0.75)
	black(c::RGB) = RGB(0,0,0)
	black(c::RGBA) = RGBA(0,0,0,0.75)
end

# ╔═╡ 7d0096ad-d89a-4ade-9679-6ee95f7d2044
begin
	function transform_xy_to_ij(img::AbstractMatrix, x::Float64, y::Float64)
	# convert coordinate system xy to ij 
	# center image, and use "white" when out of the boundary
		
		rows, cols = size(img)
		m = max(cols, rows)	
		
	    # function to take xy to ij
		xy_to_ij =  translate(rows/2, cols/2) ∘ swap ∘ flipy ∘ scale(m/2)
		
		# apply the function and "snap to grid"
		i, j = floor.(Int, xy_to_ij((x, y))) 
	
	end
	
	function getpixel(img,i::Int,j::Int; circular::Bool=false, r::Real=200)   
		#  grab image color or place default
		rows, cols = size(img)
		m = max(cols,rows)
		if circular
			c = (i-rows/2)^2 + (j-cols/2)^2 ≤ r*m^2/4
		else
			c = true
		end
		
		if 1 < i ≤ rows && 1 < j ≤ cols && c
			img[i, j]
		else
			# white(img[1, 1])
			black(img[1,1])
		end	
	end
	
	
	# function getpixel(img,x::Float64,y::Float64)
	# 	i,j = transform_xy_to_ij(img,x,y)
	# 	getpixel(img,i,j)
	# end
	
	function transform_ij_to_xy(i::Int,j::Int,pixels)	
	   ij_to_xy =  scale(2/pixels) ∘ flipy ∘ swap ∘ translate(-pixels/2,-pixels/2)
	   ij_to_xy([i,j])
	end	    
end

# ╔═╡ 99e1fc86-b6a7-44df-bc44-7262c6c2e784
transform_ij_to_xy()

# ╔═╡ da73d9f6-7a8d-11eb-2e6f-1b819bbb0185
begin
		[			    
			begin
			 x, y = transform_ij_to_xy(i,j, test_pixels)
			 X, Y =  T₁([x,y])
			 i, j = transform_xy_to_ij(test_img,X,Y)
			 getpixel(test_img,i,j)
			end	 
		
			for i = 1:test_pixels, j = 1:test_pixels
		]	
end

# ╔═╡ 30f522a0-7a8e-11eb-2181-8313760778ef
begin
		[			    
			begin
			 x, y = transform_ij_to_xy(i,j, test_pixels)
			 X, Y =  T₂([x,y])
			 i, j = transform_xy_to_ij(test_img,X,Y)
			 getpixel(test_img,i,j)
			end	 
		
			for i = 1:test_pixels, j = 1:test_pixels
		]	
end

# ╔═╡ bf1954d6-7e9a-11eb-216d-010bd761e470
transform_ij_to_xy(1,1,400)

# ╔═╡ 83d45d42-7406-11eb-2a9c-e75efe62b12c
function with_gridlines(img::Array{<:Any,2}; n = 10)
    n = 2n+1
	rows, cols = size(img)
	result = copy(img)
	# stroke = zero(eltype(img))#RGBA(RGB(1,1,1), 0.75)
	
	stroke = RGBA(1, 1, 1, 0.75)
	
	
	result[ floor.(Int, LinRange(1, rows, n)), : ] .= stroke
	# result[ ceil.(Int,LinRange(1, rows, n) ), : ] .= stroke
	result[ : , floor.(Int, LinRange(1, cols, n))] .= stroke
	# result[ : , ceil.(Int,LinRange(1, cols, n) )] .= stroke
	
	
    result[  rows ÷2    , :] .= RGBA(0,1,0,1)
	# result[  1+rows ÷2    , :] .= RGBA(0,1,0,1)
	result[ : ,  cols ÷2   ,] .= RGBA(1,0,0,1)
	# result[ : ,  1 + cols ÷2   ,] .= RGBA(1,0,0,1)
	return result
end

# ╔═╡ 55898e88-36a0-4f49-897f-e0850bd2b0df
img = if show_grid
	with_gridlines(img_original;n=ngrid)
else
	img_original
end;

# ╔═╡ ca28189e-7e9a-11eb-21d6-bd819f3e0d3a
[			    
	let
		x, y = transform_ij_to_xy(i,j, pixels)
		
		X, Y = ( translate(-panx,-pany)  )([x,y])
		X, Y = ( T⁻¹∘scale(1/z)∘translate(-panx,-pany) )([x,y])
		i, j = transform_xy_to_ij(img,X,Y) # position in the original image where this pixel would have come from 
		getpixel(img,i,j; circular=circular, r=r)
	end	 

	for i = 1:pixels, j = 1:pixels 
]

# ╔═╡ ccea7244-7f2f-11eb-1b7b-b9b8473a8c74
transform_xy_to_ij(img,0.0,0.0)

# ╔═╡ c2e0e032-7c4c-11eb-2b2a-27fe69c42a01
img

# ╔═╡ c662e3d8-7c4c-11eb-0dcf-f9da2bd14baf
size(img)

# ╔═╡ d0e9a1e8-7c4c-11eb-056c-aff283c49c31
img[50,56]

# ╔═╡ 4d0de3d3-f006-4537-a7c8-81c65f16f861
white_background(x) = PlutoUI.ExperimentalLayout.Div([x]; style="background: white")

# ╔═╡ 7c68c7b6-7a9e-11eb-3f7f-99bb10aedd95
Resource("https://raw.githubusercontent.com/mitmath/18S191/Spring21/notebooks/week3/coord_transform.png") |> white_background

# ╔═╡ 80456168-7c1b-11eb-271c-83ef59a41102
Resource("https://raw.githubusercontent.com/mitmath/18S191/Spring21/notebooks/week3/collide.png") |> white_background

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ColorVectorSpace = "c3611d14-8923-5661-9e6a-0046d554d3a4"
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
ImageIO = "82e4d734-157c-48bb-816b-45c225c6df19"
ImageShow = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
NonlinearSolve = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[compat]
ColorVectorSpace = "~0.10.0"
Colors = "~0.12.11"
FileIO = "~1.16.3"
ForwardDiff = "~0.10.36"
ImageIO = "~0.6.8"
ImageShow = "~0.3.8"
NonlinearSolve = "~3.13.1"
PlutoUI = "~0.7.59"
StaticArrays = "~1.9.7"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "ced3e7b8a0a1a948d6375b53231c2b16c0192558"

[[deps.ADTypes]]
git-tree-sha1 = "e2478490447631aedba0823d4d7a80b2cc8cdb32"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "1.14.0"
weakdeps = ["ChainRulesCore", "ConstructionBase", "EnzymeCore"]

    [deps.ADTypes.extensions]
    ADTypesChainRulesCoreExt = "ChainRulesCore"
    ADTypesConstructionBaseExt = "ConstructionBase"
    ADTypesEnzymeCoreExt = "EnzymeCore"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "3b86719127f50670efe356bc11073d84b4ed7a5d"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.42"

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    IntervalSetsExt = "IntervalSets"
    LinearAlgebraExt = "LinearAlgebra"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"
    TestExt = "Test"
    UnitfulExt = "Unitful"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cd8b948862abee8f3d3e9b73a102a9ca924debb0"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.2.0"
weakdeps = ["SparseArrays", "StaticArrays"]

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "d57bd3762d308bded22c3b82d033bff85f6195c6"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.4.0"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra"]
git-tree-sha1 = "017fcb757f8e921fb44ee063a7aafe5f89b86dd1"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.18.0"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceCUDSSExt = "CUDSS"
    ArrayInterfaceChainRulesCoreExt = "ChainRulesCore"
    ArrayInterfaceChainRulesExt = "ChainRules"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceReverseDiffExt = "ReverseDiff"
    ArrayInterfaceSparseArraysExt = "SparseArrays"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra"]
git-tree-sha1 = "4e25216b8fea1908a0ce0f5d87368587899f75be"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.ArrayLayouts.extensions]
    ArrayLayoutsSparseArraysExt = "SparseArrays"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "16351be62963a67ac4083f748fdb3cca58bfd52f"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.7"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "f21cfd4950cb9f0587d5067e69405ad2acd27b87"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.6"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "PrecompileTools", "Static"]
git-tree-sha1 = "5a97e67919535d6841172016c9530fd69494e5ec"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.2.6"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "1713c74e00545bfe14605d2a2be1712de8fbcb58"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.25.1"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CloseOpenIntervals]]
deps = ["Static", "StaticArrayInterface"]
git-tree-sha1 = "05ba0d07cd4fd8b7a39541e31a7b0254704ea581"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.13"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "403f2d8e209681fcbd9468a8514efff3ea08452e"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.29.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "362a287c3aa50601b0bc359053d5c2468f0e7ce0"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.11"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.CommonWorldInvalidations]]
git-tree-sha1 = "ae52d1c52048455e85a387fbee9be553ec2b68d0"
uuid = "f70d9fcc-98c5-4d4a-abd7-e4cdeebd8ca8"
version = "1.0.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ConcreteStructs]]
git-tree-sha1 = "f749037478283d372048690eb3b5f92a79432b34"
uuid = "2569d6c7-a4a2-43d3-a901-331e8e4be471"
version = "0.2.3"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"
weakdeps = ["IntervalSets", "LinearAlgebra", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DiffEqBase]]
deps = ["ArrayInterface", "ConcreteStructs", "DataStructures", "DocStringExtensions", "EnumX", "EnzymeCore", "FastBroadcast", "FastClosures", "FastPower", "FunctionWrappers", "FunctionWrappersWrappers", "LinearAlgebra", "Logging", "Markdown", "MuladdMacro", "Parameters", "PrecompileTools", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "SciMLStructures", "Setfield", "Static", "StaticArraysCore", "Statistics", "TruncatedStacktraces"]
git-tree-sha1 = "615e8358608628b9768275f4bd8c237724e72f08"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.164.2"

    [deps.DiffEqBase.extensions]
    DiffEqBaseCUDAExt = "CUDA"
    DiffEqBaseChainRulesCoreExt = "ChainRulesCore"
    DiffEqBaseDistributionsExt = "Distributions"
    DiffEqBaseEnzymeExt = ["ChainRulesCore", "Enzyme"]
    DiffEqBaseForwardDiffExt = ["ForwardDiff"]
    DiffEqBaseGTPSAExt = "GTPSA"
    DiffEqBaseGeneralizedGeneratedExt = "GeneralizedGenerated"
    DiffEqBaseMPIExt = "MPI"
    DiffEqBaseMeasurementsExt = "Measurements"
    DiffEqBaseMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    DiffEqBaseReverseDiffExt = "ReverseDiff"
    DiffEqBaseSparseArraysExt = "SparseArrays"
    DiffEqBaseTrackerExt = "Tracker"
    DiffEqBaseUnitfulExt = "Unitful"

    [deps.DiffEqBase.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    GTPSA = "b27dd330-f138-47c5-815b-40db9dd9b6e8"
    GeneralizedGenerated = "6b9d7cbe-bcb9-11e9-073f-15a7a543e2eb"
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.DifferentiationInterface]]
deps = ["ADTypes", "LinearAlgebra"]
git-tree-sha1 = "479214d2988a837e6d21ac38afdcb03cb2d0994e"
uuid = "a0c0ee7d-e4b9-4e03-894e-1c5f64a51d63"
version = "0.6.43"

    [deps.DifferentiationInterface.extensions]
    DifferentiationInterfaceChainRulesCoreExt = "ChainRulesCore"
    DifferentiationInterfaceDiffractorExt = "Diffractor"
    DifferentiationInterfaceEnzymeExt = ["EnzymeCore", "Enzyme"]
    DifferentiationInterfaceFastDifferentiationExt = "FastDifferentiation"
    DifferentiationInterfaceFiniteDiffExt = "FiniteDiff"
    DifferentiationInterfaceFiniteDifferencesExt = "FiniteDifferences"
    DifferentiationInterfaceForwardDiffExt = ["ForwardDiff", "DiffResults"]
    DifferentiationInterfaceGTPSAExt = "GTPSA"
    DifferentiationInterfaceMooncakeExt = "Mooncake"
    DifferentiationInterfacePolyesterForwardDiffExt = "PolyesterForwardDiff"
    DifferentiationInterfaceReverseDiffExt = ["ReverseDiff", "DiffResults"]
    DifferentiationInterfaceSparseArraysExt = "SparseArrays"
    DifferentiationInterfaceSparseMatrixColoringsExt = "SparseMatrixColorings"
    DifferentiationInterfaceStaticArraysExt = "StaticArrays"
    DifferentiationInterfaceSymbolicsExt = "Symbolics"
    DifferentiationInterfaceTrackerExt = "Tracker"
    DifferentiationInterfaceZygoteExt = ["Zygote", "ForwardDiff"]

    [deps.DifferentiationInterface.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DiffResults = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
    Diffractor = "9f5e2b26-1114-432f-b630-d3fe2085c51c"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastDifferentiation = "eb9bf01b-bf85-4b60-bf87-ee5de06c00be"
    FiniteDiff = "6a86dc24-6348-571c-b903-95158fe2bd41"
    FiniteDifferences = "26cc04aa-876d-5657-8c51-4c34ba976000"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    GTPSA = "b27dd330-f138-47c5-815b-40db9dd9b6e8"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SparseMatrixColorings = "0a514795-09f3-496d-8182-132a7b665d35"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.EnzymeCore]]
git-tree-sha1 = "0cdb7af5c39e92d78a0ee8d0a447d32f7593137e"
uuid = "f151be2c-9106-41f4-ab19-57ee4f262869"
version = "0.8.8"
weakdeps = ["Adapt"]

    [deps.EnzymeCore.extensions]
    AdaptExt = "Adapt"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.ExproniconLite]]
git-tree-sha1 = "c13f0b150373771b0fdc1713c97860f8df12e6c2"
uuid = "55351af7-c7e9-48d6-89ff-24e801d99491"
version = "0.10.14"

[[deps.FastBroadcast]]
deps = ["ArrayInterface", "LinearAlgebra", "Polyester", "Static", "StaticArrayInterface", "StrideArraysCore"]
git-tree-sha1 = "ab1b34570bcdf272899062e1a56285a53ecaae08"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.3.5"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FastLapackInterface]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "cbf5edddb61a43669710cbc2241bc08b36d9e660"
uuid = "29a986be-02c6-4525-aec4-84b980013641"
version = "2.0.4"

[[deps.FastPower]]
git-tree-sha1 = "58c3431137131577a7c379d00fea00be524338fb"
uuid = "a4df4552-cc26-4903-aec0-212e50a0e84b"
version = "1.1.1"

    [deps.FastPower.extensions]
    FastPowerEnzymeExt = "Enzyme"
    FastPowerForwardDiffExt = "ForwardDiff"
    FastPowerMeasurementsExt = "Measurements"
    FastPowerMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    FastPowerReverseDiffExt = "ReverseDiff"
    FastPowerTrackerExt = "Tracker"

    [deps.FastPower.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "2dd20384bf8c6d411b5c7370865b1e9b26cb2ea3"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.6"

    [deps.FileIO.extensions]
    HTTPExt = "HTTP"

    [deps.FileIO.weakdeps]
    HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "6a70198746448456524cb442b8af316927ff3e1a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.13.0"

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

    [deps.FillArrays.weakdeps]
    PDMats = "90014a1f-27ba-587c-ab20-58faa44d9150"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Setfield"]
git-tree-sha1 = "f089ab1f834470c525562030c8cfde4025d5e915"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.27.0"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffSparseArraysExt = "SparseArrays"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "a2df1b776752e3f344e5116c06d75a10436ab853"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.38"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FunctionWrappers]]
git-tree-sha1 = "d62485945ce5ae9c0c48f124a84998d755bae00e"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.3"

[[deps.FunctionWrappersWrappers]]
deps = ["FunctionWrappers"]
git-tree-sha1 = "b104d487b34566608f8b4e1c39fb0b10aa279ff8"
uuid = "77dc65aa-8811-40c2-897b-53d922fa7daf"
version = "0.1.3"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "83cf05ab16a73219e5f6bd1bdfa9848fa24ac627"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.2.0"

[[deps.Giflib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6570366d757b50fabae9f4315ad74d2e40c0560a"
uuid = "59f7168a-df46-5410-90c8-f2779963d0ec"
version = "5.2.3+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "1dc470db8b1131cfc7fb4c115de89fe391b9e780"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.12.0"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "8e070b599339d622e9a081d17230d74a5c473293"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.17"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "e12629406c6c4442539436581041d372d69c55ba"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.12"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "eb49b82c172811fd2c86759fa0553a2221feb909"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.7"

[[deps.ImageCore]]
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "8c193230235bbcee22c8066b0374f63b5683c2d3"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.5"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs", "WebP"]
git-tree-sha1 = "696144904b76e1ca433b886b4e7edd067d76cbf7"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.9"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "2a81c3897be6fbcde0802a0ebe6796d0562f63ec"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.10"

[[deps.ImageShow]]
deps = ["Base64", "ColorSchemes", "FileIO", "ImageBase", "ImageCore", "OffsetArrays", "StackViews"]
git-tree-sha1 = "3b5344bcdbdc11ad58f3b1956709b5b9345355de"
uuid = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
version = "0.3.8"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0936ba688c6d201805a83da835b55c61a180db52"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.11+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "0f14a5456bdc6b9731a5682f439a672750a09e48"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2025.0.4+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IntervalSets]]
git-tree-sha1 = "dba9ddf07f77f60450fe5d2e2beb9854d9a49bd0"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.10"
weakdeps = ["Random", "RecipesBase", "Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.IrrationalConstants]]
git-tree-sha1 = "e2222959fbc6c19554dc15174c81bf7bf3aa691c"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.4"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.Jieko]]
deps = ["ExproniconLite"]
git-tree-sha1 = "2f05ed29618da60c06a87e9c033982d4f71d0b6c"
uuid = "ae98c720-c025-4a4a-838c-29b094483192"
version = "0.2.1"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "fa6d0bcff8583bac20f1ffa708c3913ca605c611"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.5"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eac1206917768cb54957c65a615460d87b455fc1"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.1+0"

[[deps.KLU]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse_jll"]
git-tree-sha1 = "07649c499349dad9f08dde4243a4c597064663e9"
uuid = "ef3ab10e-7fda-4108-b977-705223b18434"
version = "0.6.0"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "b29d37ce30fa401a4563b18880ab91f979a29734"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.9.10"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aaafe88dccbd957a8d82f7d05be9b69172e0cee3"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.1+0"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "a9eaadb366f5493a5654e843864c13d8b107548c"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.17"

[[deps.LazyArrays]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "MacroTools", "SparseArrays"]
git-tree-sha1 = "866ce84b15e54d758c11946aacd4e5df0e60b7a3"
uuid = "5078a376-72f3-5289-bfd5-ec5146d43c02"
version = "2.6.1"

    [deps.LazyArrays.extensions]
    LazyArraysBandedMatricesExt = "BandedMatrices"
    LazyArraysBlockArraysExt = "BlockArrays"
    LazyArraysBlockBandedMatricesExt = "BlockBandedMatrices"
    LazyArraysStaticArraysExt = "StaticArrays"

    [deps.LazyArrays.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockArrays = "8e7c35d0-a365-5155-bbbb-fb81a777f24e"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "8be878062e0ffa2c3f67bb58a595375eda5de80b"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.11.0+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "ff3b4b9d35de638936a525ecd36e86a8bb919d11"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "df37206100d39f79b3376afb6b9cee4970041c61"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.51.1+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "4ab7581296671007fc33f07a721631b8855f4b1d"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.1+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "e4c3be53733db1051cc15ecf573b1042b3a712a1"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.3.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LinearSolve]]
deps = ["ArrayInterface", "ChainRulesCore", "ConcreteStructs", "DocStringExtensions", "EnumX", "FastLapackInterface", "GPUArraysCore", "InteractiveUtils", "KLU", "Krylov", "LazyArrays", "Libdl", "LinearAlgebra", "MKL_jll", "Markdown", "PrecompileTools", "Preferences", "RecursiveFactorization", "Reexport", "SciMLBase", "SciMLOperators", "Setfield", "SparseArrays", "Sparspak", "StaticArraysCore", "UnPack"]
git-tree-sha1 = "5ce16a2ba4acab3be950c0ccda011a10ae05ba31"
uuid = "7ed4a6bd-45f5-4d41-b270-4a48e9bafcae"
version = "2.39.0"

    [deps.LinearSolve.extensions]
    LinearSolveBandedMatricesExt = "BandedMatrices"
    LinearSolveBlockDiagonalsExt = "BlockDiagonals"
    LinearSolveCUDAExt = "CUDA"
    LinearSolveCUDSSExt = "CUDSS"
    LinearSolveEnzymeExt = "EnzymeCore"
    LinearSolveFastAlmostBandedMatricesExt = "FastAlmostBandedMatrices"
    LinearSolveHYPREExt = "HYPRE"
    LinearSolveIterativeSolversExt = "IterativeSolvers"
    LinearSolveKernelAbstractionsExt = "KernelAbstractions"
    LinearSolveKrylovKitExt = "KrylovKit"
    LinearSolveMetalExt = "Metal"
    LinearSolvePardisoExt = "Pardiso"
    LinearSolveRecursiveArrayToolsExt = "RecursiveArrayTools"

    [deps.LinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockDiagonals = "0a1fb500-61f7-11e9-3c65-f5ef3456f9f0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastAlmostBandedMatrices = "9d29842c-ecb8-4973-b1e9-a27b1157504e"
    HYPRE = "b5ffcf37-a2bd-41ab-a3da-4bd9bc8ad771"
    IterativeSolvers = "42fd0dbc-a981-5370-80f2-aaf504508153"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    KrylovKit = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    Pardiso = "46dd5b70-b6fb-5a00-ae2d-e8fea33afaf2"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "CloseOpenIntervals", "DocStringExtensions", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "PrecompileTools", "SIMDTypes", "SLEEFPirates", "Static", "StaticArrayInterface", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "8084c25a250e00ae427a379a5b607e7aed96a2dd"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.171"
weakdeps = ["ChainRulesCore", "ForwardDiff", "SpecialFunctions"]

    [deps.LoopVectorization.extensions]
    ForwardDiffExt = ["ChainRulesCore", "ForwardDiff"]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.MIMEs]]
git-tree-sha1 = "1833212fd6f580c20d4291da9c1b4e8a655b128e"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.0.0"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "oneTBB_jll"]
git-tree-sha1 = "5de60bc6cb3899cd318d80d627560fae2e2d99ae"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2025.0.1+1"

[[deps.MacroTools]]
git-tree-sha1 = "72aebe0b5051e5143a079a4685a46da330a40472"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.15"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

[[deps.MappedArrays]]
git-tree-sha1 = "2dab0221fe2b0f2cb6754eaa743cc266339f527e"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MaybeInplace]]
deps = ["ArrayInterface", "LinearAlgebra", "MacroTools"]
git-tree-sha1 = "54e2fdc38130c05b42be423e90da3bade29b74bd"
uuid = "bb5d69b7-63fc-4a16-80bd-7e42200c7bdb"
version = "0.1.4"
weakdeps = ["SparseArrays"]

    [deps.MaybeInplace.extensions]
    MaybeInplaceSparseArraysExt = "SparseArrays"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.Moshi]]
deps = ["ExproniconLite", "Jieko"]
git-tree-sha1 = "453de0fc2be3d11b9b93ca4d0fddd91196dcf1ed"
uuid = "2e0e35c7-a2e4-4343-998d-7ef72827ed2d"
version = "0.3.5"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.MuladdMacro]]
git-tree-sha1 = "cac9cc5499c25554cba55cd3c30543cff5ca4fab"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.4"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "a0b464d183da839699f4c79e7606d9d186ec172c"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.3"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "cc0a5deefdb12ab3a096f00a6d42133af4560d71"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.2"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NonlinearSolve]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "FastBroadcast", "FastClosures", "FiniteDiff", "ForwardDiff", "LazyArrays", "LineSearches", "LinearAlgebra", "LinearSolve", "MaybeInplace", "PrecompileTools", "Preferences", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SimpleNonlinearSolve", "SparseArrays", "SparseDiffTools", "StaticArraysCore", "SymbolicIndexingInterface", "TimerOutputs"]
git-tree-sha1 = "3adb1e5945b5a6b1eaee754077f25ccc402edd7f"
uuid = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
version = "3.13.1"

    [deps.NonlinearSolve.extensions]
    NonlinearSolveBandedMatricesExt = "BandedMatrices"
    NonlinearSolveFastLevenbergMarquardtExt = "FastLevenbergMarquardt"
    NonlinearSolveFixedPointAccelerationExt = "FixedPointAcceleration"
    NonlinearSolveLeastSquaresOptimExt = "LeastSquaresOptim"
    NonlinearSolveMINPACKExt = "MINPACK"
    NonlinearSolveNLSolversExt = "NLSolvers"
    NonlinearSolveNLsolveExt = "NLsolve"
    NonlinearSolveSIAMFANLEquationsExt = "SIAMFANLEquations"
    NonlinearSolveSpeedMappingExt = "SpeedMapping"
    NonlinearSolveSymbolicsExt = "Symbolics"
    NonlinearSolveZygoteExt = "Zygote"

    [deps.NonlinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    FastLevenbergMarquardt = "7a0df574-e128-4d35-8cbd-3d84502bf7ce"
    FixedPointAcceleration = "817d07cb-a79a-5c30-9a31-890123675176"
    LeastSquaresOptim = "0fc2ff8b-aaa3-5acd-a817-1944a5e08891"
    MINPACK = "4854310b-de5a-5eb6-a2a5-c1dee2bd17f9"
    NLSolvers = "337daf1e-9722-11e9-073e-8b9effe078ba"
    NLsolve = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
    SIAMFANLEquations = "084e46ad-d928-497d-ad5e-07fa361a48c4"
    SpeedMapping = "f1835b91-879b-4a3f-a438-e4baacf14412"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.OffsetArrays]]
git-tree-sha1 = "5e1897147d1ff8d98883cda2be2187dcf57d8f0c"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.15.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "97db9e07fe2091882c765380ef58ec553074e9c7"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.3"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "8292dd5c8a38257111ada2174000a33745b06d4e"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.2.4+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "cf181f0b1e6a18dfeb0ee8acc4a9d1672499626c"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.4"

[[deps.PackageExtensionCompat]]
git-tree-sha1 = "fb28e33b8a95c4cee25ce296c817d89cc2e53518"
uuid = "65ce6f38-6b18-4e1d-a461-8949797d7930"
version = "1.0.2"
weakdeps = ["Requires", "TOML"]

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "7e71a55b87222942f0f9337be62e26b1f103d3e4"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.61"

[[deps.Polyester]]
deps = ["ArrayInterface", "BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "ManualMemory", "PolyesterWeave", "Static", "StaticArrayInterface", "StrideArraysCore", "ThreadingUtilities"]
git-tree-sha1 = "6d38fea02d983051776a856b7df75b30cf9a3c1f"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.7.16"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "645bed98cd47f72f67316fd42fc47dee771aefcd"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "8f6bc219586aef8baf0ff9a5fe16ee9c70cb65e4"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.10.2"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "8b3fc30bc0390abdce15f8822c889f669baed73d"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.1"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "e96b644f7bfbf1015f8e42a7c7abfae2a48fafbf"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "3.31.0"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsFastBroadcastExt = "FastBroadcast"
    RecursiveArrayToolsForwardDiffExt = "ForwardDiff"
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    RecursiveArrayToolsReverseDiffExt = ["ReverseDiff", "Zygote"]
    RecursiveArrayToolsSparseArraysExt = ["SparseArrays"]
    RecursiveArrayToolsStructArraysExt = "StructArrays"
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    FastBroadcast = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization", "Polyester", "PrecompileTools", "StrideArraysCore", "TriangularSolve"]
git-tree-sha1 = "6db1a75507051bc18bfa131fbc7c3f169cc4b2f6"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.2.23"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "04c968137612c4a5629fa531334bb81ad5680f00"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.13"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "fea870727142270bdf7624ad675901a1ee3b4c87"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.7.1"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "456f610ca2fbd1c14f5fcf31c6bfadc55e7d66e0"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.43"

[[deps.SciMLBase]]
deps = ["ADTypes", "Accessors", "ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "EnumX", "FunctionWrappersWrappers", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "Markdown", "Moshi", "PrecompileTools", "Preferences", "Printf", "RecipesBase", "RecursiveArrayTools", "Reexport", "RuntimeGeneratedFunctions", "SciMLOperators", "SciMLStructures", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface"]
git-tree-sha1 = "ee305515b0946db5f56af699e8b5804fee04146c"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "2.75.1"

    [deps.SciMLBase.extensions]
    SciMLBaseChainRulesCoreExt = "ChainRulesCore"
    SciMLBaseMLStyleExt = "MLStyle"
    SciMLBaseMakieExt = "Makie"
    SciMLBasePartialFunctionsExt = "PartialFunctions"
    SciMLBasePyCallExt = "PyCall"
    SciMLBasePythonCallExt = "PythonCall"
    SciMLBaseRCallExt = "RCall"
    SciMLBaseZygoteExt = "Zygote"

    [deps.SciMLBase.weakdeps]
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    MLStyle = "d8e11817-5142-5d16-987a-aa16d5891078"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    PartialFunctions = "570af359-4316-4cb7-8c74-252c00c2016b"
    PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
    PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
    RCall = "6f49c342-dc21-5d91-9882-a32aef131414"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.SciMLOperators]]
deps = ["Accessors", "ArrayInterface", "DocStringExtensions", "LinearAlgebra", "MacroTools"]
git-tree-sha1 = "6149620767866d4b0f0f7028639b6e661b6a1e44"
uuid = "c0aeaf25-5076-4817-a8d5-81caf7dfa961"
version = "0.3.12"
weakdeps = ["SparseArrays", "StaticArraysCore"]

    [deps.SciMLOperators.extensions]
    SciMLOperatorsSparseArraysExt = "SparseArrays"
    SciMLOperatorsStaticArraysCoreExt = "StaticArraysCore"

[[deps.SciMLStructures]]
deps = ["ArrayInterface"]
git-tree-sha1 = "566c4ed301ccb2a44cbd5a27da5f885e0ed1d5df"
uuid = "53ae85a6-f571-4167-b2af-e1d143709226"
version = "1.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "c5391c6ace3bc430ca630251d02ea9687169ca68"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.2"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.SimpleNonlinearSolve]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "DiffResults", "DifferentiationInterface", "FastClosures", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "MaybeInplace", "PrecompileTools", "Reexport", "SciMLBase", "Setfield", "StaticArraysCore"]
git-tree-sha1 = "44021f3efc023be3871195d8ad98b865001a2fa1"
uuid = "727e6d20-b764-4bd8-a329-72de5adea6c7"
version = "1.12.3"

    [deps.SimpleNonlinearSolve.extensions]
    SimpleNonlinearSolveChainRulesCoreExt = "ChainRulesCore"
    SimpleNonlinearSolveReverseDiffExt = "ReverseDiff"
    SimpleNonlinearSolveTrackerExt = "Tracker"
    SimpleNonlinearSolveZygoteExt = "Zygote"

    [deps.SimpleNonlinearSolve.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "2da10356e31327c7096832eb9cd86307a50b1eb6"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.SparseDiffTools]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "Graphs", "LinearAlgebra", "PackageExtensionCompat", "Random", "Reexport", "SciMLOperators", "Setfield", "SparseArrays", "StaticArrayInterface", "StaticArrays", "UnPack", "VertexSafeGraphs"]
git-tree-sha1 = "d79802152d958607f414f5447cb25e314db979c0"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "2.23.1"

    [deps.SparseDiffTools.extensions]
    SparseDiffToolsEnzymeExt = "Enzyme"
    SparseDiffToolsPolyesterExt = "Polyester"
    SparseDiffToolsPolyesterForwardDiffExt = "PolyesterForwardDiff"
    SparseDiffToolsSymbolicsExt = "Symbolics"
    SparseDiffToolsZygoteExt = "Zygote"

    [deps.SparseDiffTools.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    Polyester = "f517fe37-dbe3-4b94-8317-1923a5111588"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Sparspak]]
deps = ["Libdl", "LinearAlgebra", "Logging", "OffsetArrays", "Printf", "SparseArrays", "Test"]
git-tree-sha1 = "342cf4b449c299d8d1ceaf00b7a49f4fbc7940e7"
uuid = "e56a9233-b9d6-4f03-8d0f-1825330902ac"
version = "0.3.9"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "64cca0c26b4f31ba18f13f6c12af7c85f478cfde"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.5.0"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Static]]
deps = ["CommonWorldInvalidations", "IfElse", "PrecompileTools"]
git-tree-sha1 = "87d51a3ee9a4b0d2fe054bdd3fc2436258db2603"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "1.1.1"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "Static"]
git-tree-sha1 = "96381d50f1ce85f2663584c8e886a6ca97e60554"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.8.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "0feb6b9031bd5c51f9072393eb5ab3efd31bf9e4"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.13"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StrideArraysCore]]
deps = ["ArrayInterface", "CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface", "ThreadingUtilities"]
git-tree-sha1 = "f35f6ab602df8413a50c4a25ca14de821e8605fb"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.5.7"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.SymbolicIndexingInterface]]
deps = ["Accessors", "ArrayInterface", "RuntimeGeneratedFunctions", "StaticArraysCore"]
git-tree-sha1 = "d6c04e26aa1c8f7d144e1a8c47f1c73d3013e289"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.3.38"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "eda08f7e9818eb53661b3deb74e3159460dfbc27"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.2"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "SIMD", "UUIDs"]
git-tree-sha1 = "f21231b166166bebc73b99cea236071eb047525b"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.11.3"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "f57facfd1be61c42321765d3551b3df50f7e09f6"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.28"

    [deps.TimerOutputs.extensions]
    FlameGraphsExt = "FlameGraphs"

    [deps.TimerOutputs.weakdeps]
    FlameGraphs = "08572546-2f56-4bcf-ba4e-bab62c3a3f89"

[[deps.TriangularSolve]]
deps = ["CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "LoopVectorization", "Polyester", "Static", "VectorizationBase"]
git-tree-sha1 = "be986ad9dac14888ba338c2554dcfec6939e1393"
uuid = "d5829a12-d9aa-46ab-831f-fb7c9ab06edf"
version = "0.2.1"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.TruncatedStacktraces]]
deps = ["InteractiveUtils", "MacroTools", "Preferences"]
git-tree-sha1 = "ea3e54c2bdde39062abf5a9758a23735558705e1"
uuid = "781d530d-4396-4725-bb49-402e4bee1e77"
version = "1.4.0"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "4ab62a49f1d8d9548a1c8d1a75e5f55cf196f64e"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.71"

[[deps.VertexSafeGraphs]]
deps = ["Graphs"]
git-tree-sha1 = "8351f8d73d7e880bfc042a8b6922684ebeafb35c"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.2.0"

[[deps.WebP]]
deps = ["CEnum", "ColorTypes", "FileIO", "FixedPointNumbers", "ImageCore", "libwebp_jll"]
git-tree-sha1 = "aa1ca3c47f119fbdae8770c29820e5e6119b83f2"
uuid = "e3aaa7dc-3e4b-44e0-be63-ffb868ccd7c1"
version = "0.1.3"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "b8b243e47228b4a3877f1dd6aee0c5d56db7fcf4"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.6+1"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "7d1671acbe47ac88e981868a078bd6b4e27c5191"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.42+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "56c6604ec8b2d82cc4cfe01aa03b00426aac7e1f"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.6.4+1"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "9dafcee1d24c4f024e7edc92603cedba72118283"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+3"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e9216fdcd8514b7072b43653874fd688e4c6c003"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.12+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "89799ae67c17caa5b3b5a19b8469eeee474377db"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.5+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "d7155fea91a4123ef59f42c4afb5ab3b4ca95058"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.6+3"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c57201109a9e4c0585b208bb408bc41d205ac4e9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.2+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "1a74296303b6524a0472a8cb12d3d87a78eb3612"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.0+3"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6dba04dbfb72ae3ebe5418ba33d087ba8aa8cb00"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.1+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "446b23e73536f84e8037f5dce465e92275f6a308"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "068dfe202b0a05b8332f1e8e6b4080684b9c7700"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.47+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "libpng_jll"]
git-tree-sha1 = "c1733e347283df07689d71d61e14be986e49e47a"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.5+0"

[[deps.libwebp_jll]]
deps = ["Artifacts", "Giflib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libglvnd_jll", "Libtiff_jll", "libpng_jll"]
git-tree-sha1 = "d2408cac540942921e7bd77272c32e58c33d8a77"
uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2"
version = "1.5.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.oneTBB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d5a767a3bb77135a99e433afe0eb14cd7f6914c3"
uuid = "1317d2d5-d96f-522e-a858-c73665f53c3e"
version = "2022.0.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─b7895bd2-7634-11eb-211e-ef876d23bd88
# ╟─230b0118-30b7-4035-ad31-520165a76fcc
# ╠═6b473b2d-4326-46b4-af38-07b61de287fc
# ╟─890d30b9-2cd0-4d3a-99f6-f7d3d7858fda
# ╠═bb149122-7f62-4b60-a9fd-4455ff02fa9d
# ╠═96766502-7a06-11eb-00cc-29849773dbcf
# ╠═d495e48b-99d2-45b0-b40f-09f57643dfd5
# ╟─e0b657ce-7a03-11eb-1f9d-f32168cb5394
# ╟─005ca75a-7622-11eb-2ba4-9f450e71df1f
# ╟─23ade8ee-7a09-11eb-0e40-296c6b831d74
# ╠═58a30e54-7a08-11eb-1c57-dfef0000255f
# ╟─2efaa336-7630-11eb-0c17-a7d4a0141dac
# ╟─7f28ac40-7914-11eb-1403-b7bec34aeb94
# ╠═b76a5bd6-802f-11eb-0951-1f1092dee8de
# ╟─5d33f6ea-7e9c-11eb-2fb3-dbb7cb07c60c
# ╟─45dccdec-7912-11eb-01b4-a97e30344f39
# ╟─d2fb356e-7f32-11eb-177d-4f47d6c9e59b
# ╟─ce55beee-7643-11eb-04bc-b517703facff
# ╠═ca28189e-7e9a-11eb-21d6-bd819f3e0d3a
# ╠═4fe8f309-9d9a-495e-a768-c7771bcc654d
# ╠═ccea7244-7f2f-11eb-1b7b-b9b8473a8c74
# ╠═99e1fc86-b6a7-44df-bc44-7262c6c2e784
# ╟─55b5fc92-7a76-11eb-3fba-854c65eb87f9
# ╠═85686412-7a75-11eb-3d83-9f2f8a3c5509
# ╟─a7df7346-79f8-11eb-1de6-71f027c46643
# ╟─044e6128-79fe-11eb-18c1-395ae857dc73
# ╟─78d61e28-79f9-11eb-0605-e77d206cda84
# ╟─aad4d6e4-79f9-11eb-0342-b900a41cfbaf
# ╟─d42aec08-76ad-11eb-361a-a1f2c90fd4ec
# ╟─d9115c1a-7aa0-11eb-38e4-d977c5a6b75b
# ╟─e965cf5e-79fd-11eb-201d-695b54d08e54
# ╟─1e11c1ec-79fe-11eb-1867-9da72b3f3bc4
# ╟─28ef451c-7aa1-11eb-340c-ab3a1193a3c4
# ╟─a0afe3ae-76b9-11eb-2301-cde7260ddd7f
# ╟─fc2deb7c-7aa1-11eb-019f-d3e3c80b9ff1
# ╠═d364f91a-76b9-11eb-1807-75e733940d53
# ╟─080d87e0-7aa2-11eb-18f5-2fb6a7a5bcb4
# ╠═15283aba-7aa2-11eb-389c-e9f215bd03e2
# ╠═b77afa13-8754-40c5-947d-b9c3badefcf6
# ╟─2612d2c2-7aa2-11eb-085a-1f27b6174995
# ╟─a290d5e2-7a02-11eb-37db-41bf86b1f3b3
# ╠═50d80844-e8bb-4c84-9bc2-15f547f0e3a9
# ╠═5677b510-bd37-4e6c-b20c-0a9d578e3ed0
# ╠═09e961c1-4e25-4589-ad17-04d747053475
# ╠═a591552b-d0dd-49a5-ad08-7b59d4e0b34d
# ╠═58e5bc84-50ad-4ecc-a191-7ccf3fa3a1fd
# ╠═4b097c6e-e22c-451f-acb6-bfbfe9a0110f
# ╠═a8577554-7997-4f35-bfa2-26f1b58813e4
# ╟─704a87ec-7a1e-11eb-3964-e102357a4d1f
# ╠═4b0e8742-7a70-11eb-1e78-813f6ad005f4
# ╟─44792484-7a20-11eb-1c09-95b27b08bd34
# ╟─f650b788-7a70-11eb-0b20-779d2f18f111
# ╟─c852d398-7aa2-11eb-2ded-ab2e5236e9b2
# ╟─061076c2-7aa3-11eb-0d04-b7cbc60e6cb2
# ╟─014c14a6-7a72-11eb-119b-f5cfc82085ca
# ╟─89f0bc54-76bb-11eb-271b-3190b4d8cbc0
# ╟─f70f7ea8-76b9-11eb-3bd7-87d40a2861b1
# ╟─bf28c388-76bd-11eb-08a7-af2671218017
# ╠═5655d2a6-76bd-11eb-3042-5b2dd3f6f44e
# ╠═56f1e4cc-7a03-11eb-187b-c5a917978eb9
# ╠═70dc4346-7a03-11eb-055e-111d2519a44c
# ╠═852592d6-76bd-11eb-1265-5f200e39113d
# ╠═8e36f4a2-76bd-11eb-2fda-9d1424752812
# ╟─a8bf7128-7aa5-11eb-3ee9-953b0b5ccd01
# ╟─ad700740-7a74-11eb-3369-15e5fd89194d
# ╟─e051259a-7a74-11eb-12fc-99c5dc867fbd
# ╟─1856ddae-7a78-11eb-3422-298e1103275b
# ╟─4b4fe818-7a78-11eb-2986-59e60063d346
# ╟─5d656494-7a78-11eb-12e8-d17856bd8c4d
# ╟─b0e6d1ac-7a7d-11eb-0a9e-1310dcb5957f
# ╟─7e4ad37c-7a84-11eb-1490-25090e133a7c
# ╟─96f47252-7a84-11eb-3d18-e3ba79dd20c2
# ╟─ae5b3a32-7a84-11eb-04c0-337a74105a58
# ╟─c9f2b61e-7a84-11eb-3841-33739a226ff9
# ╟─23d8a45c-7a85-11eb-3a68-ef11e6f58cac
# ╟─4a96d516-7a85-11eb-181c-63a6b461790b
# ╠═8206e1ee-7a8a-11eb-1f26-054f6b100076
# ╟─7d803684-7a8a-11eb-33d2-89d5e2a05bcf
# ╟─17281256-7aa5-11eb-3144-b72777334326
# ╠═05049fa0-7a8e-11eb-283b-cb4753c4aaf0
# ╠═350f40f7-795f-4f33-89b8-ff9ba4819e1c
# ╠═313cdcbd-5b11-41c8-9fcd-5aeaca3b8d24
# ╟─57848b42-7a8f-11eb-023a-cf247cb53819
# ╟─da73d9f6-7a8d-11eb-2e6f-1b819bbb0185
# ╟─620ee7d8-7a8f-11eb-3888-356c27a2d591
# ╟─30f522a0-7a8e-11eb-2181-8313760778ef
# ╟─04da7710-7a91-11eb-02a1-0b6e889150a2
# ╠═c2e0e032-7c4c-11eb-2b2a-27fe69c42a01
# ╠═c662e3d8-7c4c-11eb-0dcf-f9da2bd14baf
# ╠═d0e9a1e8-7c4c-11eb-056c-aff283c49c31
# ╟─155cd218-7a91-11eb-0b4c-bd028507e925
# ╟─fd25da12-7a92-11eb-20c0-995e7c46b3bc
# ╟─1ab2265e-7c1d-11eb-26df-39c4c7289243
# ╟─7c68c7b6-7a9e-11eb-3f7f-99bb10aedd95
# ╠═7d0096ad-d89a-4ade-9679-6ee95f7d2044
# ╠═bf1954d6-7e9a-11eb-216d-010bd761e470
# ╠═c1efc54a-7e9b-11eb-1e76-dbd0a66184a9
# ╟─db4bc328-76bb-11eb-28dc-eb9df8892d01
# ╟─0b8ed36c-7a1e-11eb-053c-63cf9ee0b16f
# ╟─7a4e785e-7a71-11eb-07fb-cfba453a117b
# ╠═9264508a-7a71-11eb-1b7c-bf6e62788115
# ╠═e89339b2-7a71-11eb-0f97-971b2ed277d1
# ╟─0957fd9a-7a72-11eb-0566-e93ef32fb626
# ╟─c7cc412c-7aa5-11eb-2df1-d3d788047238
# ╟─ce620b8e-7aa5-11eb-370b-11e34b07d54d
# ╟─4f51931c-7aac-11eb-13ba-4b8768ac376f
# ╠═5ce799f4-7aac-11eb-0629-ebd8a404e9d3
# ╠═9b456686-7aac-11eb-3aa5-25e6c3c86aff
# ╟─c2b0a488-7aac-11eb-1d8b-edd6bd23d1fd
# ╟─02d6b440-7aa7-11eb-1be0-b78dea91387f
# ╟─0be9fb1e-7aa7-11eb-0116-c3e86ab82c77
# ╟─7609d686-7aa7-11eb-310a-3550509504a1
# ╟─1b9faf64-7aab-11eb-1396-6fb89be7c445
# ╟─5f0568dc-7aad-11eb-162f-0d6e26f17d59
# ╟─8d32fff4-7c1b-11eb-1fa1-6ff2d87bfb73
# ╠═80456168-7c1b-11eb-271c-83ef59a41102
# ╠═62a9201c-7938-11eb-144c-15690c06be94
# ╟─5227afd0-7641-11eb-0065-918cb8538d55
# ╟─4c93d784-763d-11eb-1f48-81d4d45d5ce0
# ╟─c536dafb-4206-4689-ad6d-6935385d8fdf
# ╠═fb509fb4-9608-421d-9c40-a4375f459b3f
# ╠═55898e88-36a0-4f49-897f-e0850bd2b0df
# ╠═b754bae2-762f-11eb-1c6a-01251495a9bb
# ╟─83d45d42-7406-11eb-2a9c-e75efe62b12c
# ╟─4d0de3d3-f006-4537-a7c8-81c65f16f861
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
