im = zeros(480,640,3);


for j = 1:480
    for i = 1:640
        if(x(j,i) == 1)
            im(j,i,:) = [255 0 0];
        elseif(x(j,i) == 2)
            im(j,i,:) = [0 255 0];
        elseif(x(j,i) == 3)
            im(j,i,:) = [255 255 0];
        elseif(x(j,i) == 4)
            im(j,i,:) = [0 0 255];
        end            
        
    end
end

imwrite(im,'18gt.png', 'PNG');