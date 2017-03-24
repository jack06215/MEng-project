function [ AA ] = rotMat2axisAngle ( R )
%ROTMAT2AXISANGLE Summary
%   Detailed explanation goes here

% get eigen vectors and values
[ V, D ] = eig( R );

% set axis to eigenVector column with corresponding value of 1
[ row, col ] = find( abs( 1 - D ) < 0.0001 ); % TODO: less wasteful ways to do this? (lamda moded by size(D,2))?
rn = V( :, col );

% find theta 
cosTheta = ( trace( R ) - 1 ) / 2;
sincTheta = [ R( 3, 2 ) - R( 2, 3 ), R( 1, 3 ) - R( 3, 1 ), R( 2, 1 )-R( 1, 2 ) ]' ./ ( 2 * rn );
sinTheta = sincTheta * norm( rn );

theta = atan2( sinTheta, cosTheta ); 
theta = theta( 1 ); % NOTE: atan2 above returns a 3x1 matrix which is ok since all the values are the same, but we need a single number

AA = [ rn; theta ]; % TODO: signs are reversed (should technically be ok since it is simmetrical to negated axis angle... as long as all the numbers are correct)
end
