function [g, i] = gepi(kxm, kym, nl, varargin)
  %
  %  generates an epi trajectory, with the readout dimension along x and the
  %  phase-encode dimension along y.
  %
  %  note:
  %  the k-space extents 'kxm' and 'kym' are in units of 1/cm, so the gradients
  %  depend on the gyromagnetic ratio 'gam', set for proton by default.
  %
  %  function [g i] = gepi(kxm, kym, nl, varargin)
  %
  %  inputs ....................................................................
  %  kxm              max kx position (total kx extent is +/- kxm). (1/cm)
  %  kym              max ky position (total ky extent is +/- kym). (1/cm)
  %  nl               # lines, or kx trapezoids. (int)
  %
  %  options ...................................................................
  %  gm               max gradient amplitude. (G/cm) (default = 4)
  %  sm               max slew-rate. (G/cm/ms) (default = 15)
  %  dt               sample time. (ms) (default = .004)
  %  gam              gyromagnetic ratio. (kHz/G) (default = 4.258)
  %
  %  outputs ...................................................................
  %  g                epi gradients. the 1st column contains the readout, and
  %                   the 2nd column the phase-encodes. [points axis] (G/cm)
  %

  % set default arguments
  v = ap2s(varargin);
  dt  = def(v, 'dt', .004);
  gam = def(v, 'gam', 4.258);
  gm  = def(v, 'gm', 4);
  sm  = def(v, 'sm', 15);

  % readout gradient
  g1 = gtrap(gm, sm, 'area', 2*kxm);
  l1 = length(g1);
  z1 = zeros(1, l1);

  % phase-encode blip
  dky = 2*kym/(nl-1);
  g2 = gtrap(gm, sm, 'area', -dky);
  l2 = length(g2);
  z2 = zeros(1, l2);

  % rephasers
  g3 = gtrap(gm, sm, 'area', kxm);
  g4 = gtrap(gm, sm, 'area', kym);
  
  % make rephasers the same length
  padl = @(x) max(x)-x;
  ll = padl([length(g4) length(g3)]);
  g4 = [g4 zeros(1, ll(1))];
  g3 = [g3 zeros(1, ll(2))];
  l3 = length(g3);
  gx = []; gy = [];
  
  % make readout gradient zig-zag, and repeat blips
  for i = 1:nl
    gx = [gx -(-1)^i*g1 z2];
    gy = [gy z1 g2];
  end
  
  % remove last blip, and add rephasers
  gx = [-g3 gx(1:end-l2) (-1)^nl*g3];
  gy = [g4 gy(1:end-l2) g4];
  g = [gx(:) gy(:)];

  % struct with various information
  i = {};
  i.ldep = l3;
  i.ltrap = l1;
  i.lblip = l2;
  i.itrap = l3+[1,l1];
  i.iblip = l3+l1+[1,l2];

end
