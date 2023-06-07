% Calculated the difference (in deg) between two vectors of orientations,
% and assumes your orientation space runs from 1:180. Hacky but fool-proof
function delta_orient = diff_in_deg(input1, input2)

% error checking
if size(input1) ~= size(input2)
    error('sizes of your inputs don''t match')
end

% make right size 
if size(input1,1)>1
    input1 = input1'; input2 = input2';
end

% whatever, it works
delta_orient(1,:) = abs(input2-input1);
delta_orient(2,:) = abs((360-(delta_orient(1,:)*2))/2);
delta_orient(3,:) = 360-(delta_orient(1,:));
delta_orient = min(delta_orient);
%Add minus signs back in
delta_orient(mod(input1-delta_orient,360)==input2)=-delta_orient(mod(input1-delta_orient,360)==input2);
delta_orient(mod((input1+180)-delta_orient,360)==input2)=-delta_orient(mod((input1+180)-delta_orient,360)==input2);