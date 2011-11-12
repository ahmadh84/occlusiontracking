####### Compiler, tools and options
CC            = /usr/bin/gcc-4.6
CXX           = /usr/bin/g++-4.4
LINK          = /usr/bin/g++-4.4
CXXFLAGS      = -m64 -O2 -Wall
LFLAGS        = `pkg-config opencv --cflags --libs`
RELEASEDIR    = ../Release/
DEBUGDIR      = ../Debug/
TARGET        = predictDescriptor
COMPILERFLAGS =
BUILDDIR      =


####### Files
SOURCES       = predictDescriptor.cpp
OBJECTS       = predictDescriptor.o


####### Build rules
all: Makefile $(TARGET)

$(TARGET):  $(OBJECTS)  
	$(LINK) $(COMPILERFLAGS) $(LFLAGS) -o $(BUILDDIR)$(TARGET) $(OBJECTS)

release: BUILDDIR = $(RELEASEDIR)
release: preparebuild all

cleanrelease: BUILDDIR = $(RELEASEDIR)
cleanrelease: clean

debug: BUILDDIR = $(DEBUGDIR)
debug: COMPILERFLAGS += -DDEBUG -g
debug: preparebuild all

cleandebug: BUILDDIR = $(DEBUGDIR)
cleandebug: clean

preparebuild:
	@if test -d $(BUILDDIR); then \
		echo "Building in $(BUILDDIR) directory!"; \
	else \
		mkdir $(BUILDDIR); \
		echo "Building in $(BUILDDIR) directory!"; \
	fi

clean:
	rm $(OBJECTS)
	rm $(BUILDDIR)$(TARGET)


####### Compile
predictDescriptor.o: predictDescriptor.cpp
	$(CXX) -c $(CXXFLAGS) $(COMPILERFLAGS) $(LFLAGS) -o predictDescriptor.o predictDescriptor.cpp
