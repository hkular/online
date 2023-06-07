function output = circ_mean_of_vals_deg(input)
% output: the circular mean of a vector of intensity values (note: the
% input is not degrees) for an orientation space defined in degrees (1:180)
%
% input: needs to be a 1 x num_values vector
%
% Written by RR, June 4th 2018

output = (rad2deg(circ_mean(deg2rad(2:2:360)',(input*2)'))/2);

if sign(output) == -1
    output = 180+output;
end



