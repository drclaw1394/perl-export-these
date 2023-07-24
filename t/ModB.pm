package Module::B;
use Export::These (
  "sub3", 
    tags=>{group1=>[qw<sub4>]}
);

sub sub3 {
"Sub3";
}
sub sub4 {
"Sub4";
}
1;
