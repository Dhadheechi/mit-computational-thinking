using Images, ImageView, Statistics

function draw_seam(img, seam)
    # for each row of the img, the array seam contains the column numbers where the seam exists
    img_with_seam = copy(img)
    for i in 1:size(img)[1]
        img_with_seam[i, seam[i]] = RGB(1, 0, 1)
    end

    return img_with_seam
end

function brightness(img_element::AbstractRGB)
    return (img_element.r + img_element.g + img_element.r) / 3
end

function find_energy(img)
    energy_x = imfilter(brightness.(img), Kernel.sobel()[2]) # applying a filter to an image
    energy_y = imfilter(brightness.(img), Kernel.sobel()[1])

    return sqrt.(energy_x.^2 + energy_y.^2) # magnitude of the gradient at each of the points. 

end

function find_energy_map(energy)
    energy_map = zeros(size(energy))
    next_elements = zeros(Int, size(energy))

    energy_map[end, :] = energy[end, :]

    for i in size(energy)[1]-1:-1:1
        for j in 1:size(energy)[2]
            left = max(1, j-1)
            right = min(size(energy)[2], j+1)
            local_energy, next_element = findmin(energy_map[i+1, left:right])

            energy_map[i,j] = energy[i,j] + local_energy
            next_elements[i,j] = next_element - 2 # 1:3 to -1:1

            if j == 1
                next_elements[i,j] += 1
            end
        end
    end
    return energy_map, next_elements
end

function find_seam_at(next_elements, element)
    seam = zeros(Int, size(next_elements)[1]) # represent the indices of a seam

    seam[1] = element 
    
    for i in 2:length(seam)
        seam[i] = seam[i-1] + next_elements[i-1, seam[i-1]] # the next element is either -1 / 0 / 1
    end

    return seam 
end

function find_min_seam(energy)
    energy_map, next_elements = find_energy_map(energy)

    _, min_element = findmin(energy_map[1, :]) # we only need the index corresponding to the minimum index at the top
    seam = find_seam_at(next_elements, min_element)

    return seam 
end

function remove_seam(img, seam)
    img_res = (size(img)[1], size(img)[2] - 1) # we want to have one less column

    # preallocate the image
    new_img = Array{RGB}(undef, img_res) # we have 

    for i in eachindex(seam)
        if seam[i] > 1 || seam[i] < size(img)[2]
            new_img[i, :] .= vcat(img[i, 1:seam[i] -1], img[i, seam[i]+1 : end])
        elseif seam[i] == 1 # the seam of the ith row passes through the first column
            new_img[i, :] .= img[i, 2:end]
        elseif seam[i] == size(img)[2]
            new_img[i, :] .= img[i, 1:end-1]
        end 
    end 

    return new_img
end

function seam_carving(img, res)
    if res < 0 || res > size(img)[2]
        error("Resolution not acceptable")
    end
    
    for i in (1:size(img)[2]-res) # we have to remove these many seams from the image
        energy = find_energy(img)
        seam = find_min_seam(energy)
        img = remove_seam(img, seam)
    end

    return img
end

function convert_to_float64(img::Matrix{RGB})
    return RGBA{Float64}.(img)  # Broadcast conversion
end

