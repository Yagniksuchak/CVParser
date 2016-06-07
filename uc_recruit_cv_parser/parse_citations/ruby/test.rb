require 'anystyle/parser'
require 'json'
print "
"
c = Anystyle.parse"V.M. Abazov et al. [D0 Collaboration], “Combined search for the standard model Higgs boson decaying to bb using the D0 Run II data” Phys. Rev. Lett. 109, 121802 (2012) [arXiv:1207.6631]."
print c.to_json
print "
"
c = Anystyle.parse"J. B. Lucks, A. J. Cohen, N. C. Handy* (2002). Constructing a map from the electron density to the exchange-correlation potential. Physical Chemistry Chemical Physics, 4, 4612-4618."
print c.to_json
print "
"
c = Anystyle.parse"Shukla S., Safeeq M., AghaKouchak A., Guan K., Funk C., 2015, Temperature Impacts on the Water Year 2014 Drought in California, Geophysical Research Letters, 42, 4384- 4393, doi:10.1002/2015GL063666."
print c.to_json
