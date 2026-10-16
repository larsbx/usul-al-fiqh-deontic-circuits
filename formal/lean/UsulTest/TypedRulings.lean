import Usul.Tarjih
import Usul.Reconcile

/- PR-33: Python emits canonical JSON keys as Lean Strings. These fixed
expectations are independent of Python's resolver. Neither bool/int nor
scalar/text collisions may collapse two proof or attribution sides. -/
namespace UsulTest.TypedRulings

def pairs : List (String × String) :=
  [("false", "0"), ("true", "1"), ("false", "\"false\""),
   ("true", "\"true\""), ("1", "\"1\"")]

#guard pairs.all fun (a, b) => a != b
#guard pairs.all fun (a, b) => Usul.Tarjih.top [(a, .qiyas)] b == none
#guard pairs.all fun (a, b) => Usul.Reconcile.prevail [(a, .nass), (b, .nass)] == none

#guard [Usul.Tarjih.Policy.strict, .sources, .applying, .all].all fun policy =>
  pairs.all fun (a, b) =>
    Usul.Tarjih.reconcile policy none none [a, b] [(a, .qiyas), (b, .qiyas)] [] == .tawaqquf

#guard [Usul.Tarjih.Policy.strict, .sources, .applying, .all].all fun policy =>
  pairs.all fun (a, b) =>
    Usul.Tarjih.reconcile policy none none [a, b] [(a, .zanni), (b, .qiyas)] [] == .tarjih a

end UsulTest.TypedRulings
