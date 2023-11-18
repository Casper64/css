module pref

@[heap; params]
pub struct Preferences {
pub mut:
	is_strict       bool
	suppress_output bool
}
