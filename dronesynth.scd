MIDIClient.init;
MIDIIn.connectAll;


s.boot
s.scope
(
SynthDef.new("tutorial-args", { arg freq = 440, out = 0;
	Out.ar(out, SinOsc.ar(freq, 0, 0.2));
}).add;
)

(
~snths = [
	Synth("tutorial-args", ["out", 0]),
	Synth("tutorial-args", ["out", 1]),
	Synth("tutorial-args", ["out", 0]),
	Synth("tutorial-args", ["out", 1]),
	Synth("tutorial-args", ["out", 0]),
	Synth("tutorial-args", ["out", 1]),
	Synth("tutorial-args", ["out", 0]),
	Synth("tutorial-args", ["out", 1])
];
)

MIDIFunc.cc({ |val, deviceNum, chan, src|
	"val: " + val.postln;
	"num: " + deviceNum.postln;
	"chan: " + chan.postln;
	"src: " + src.postln;
	"-----".postln;
	~snths[deviceNum].set("freq", val * 8);
});


/*
x.set("freq", 660);
x.set("freq", 660, "out", 0);
y.set("freq", 880, "out", 1);
*/


//x.free;y.free;
