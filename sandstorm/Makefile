# You may override the following vars on the command line to suit
# your config.
CXX=clang++
CXXFLAGS=-O2 -Wall

# You generally should not modify these.
CXXFLAGS2=-std=c++1y -Itmp $(CXXFLAGS)

.PHONY: all clean

all: bin/sandstorm-getPublicAddress bin/sandstorm-getUserAddress

clean:
	rm -rf bin tmp node_modules bundle shell-bundle.tar.gz sandstorm-*.tar.xz shell/public/edit.png shell/public/trash.png shell/public/wrench.png shell/public/download.png .shell-env

bin/sandstorm-getPublicAddress: tmp/genfiles sandstorm-getPublicAddress.c++
	@mkdir -p bin
	@$(CXX) sandstorm-getPublicAddress.c++ tmp/sandstorm/*.capnp.c++ -o bin/sandstorm-getPublicAddress -static $(CXXFLAGS2) `pkg-config capnp-rpc --cflags --libs`

bin/sandstorm-getUserAddress: tmp/genfiles sandstorm-getUserAddress.c++
	@mkdir -p bin
	@$(CXX) sandstorm-getUserAddress.c++ tmp/sandstorm/*.capnp.c++ -o bin/sandstorm-getUserAddress -static $(CXXFLAGS2) `pkg-config capnp-rpc --cflags --libs`

tmp/genfiles: /opt/sandstorm/latest/usr/include/sandstorm/*.capnp
	@echo "generating capnp files..."
	@mkdir -p tmp
	@capnp compile --src-prefix=/opt/sandstorm/latest/usr/include -oc++:tmp  /opt/sandstorm/latest/usr/include/sandstorm/*.capnp
	@touch tmp/genfiles