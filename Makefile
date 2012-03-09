PYTHON = python
CHECKSCRIPT = kivy/tools/pep8checker/pep8kivy.py
KIVY_DIR = kivy/
HOSTPYTHON = $(KIVYIOSROOT)/tmp/Python-$(PYTHON_VERSION)/hostpython
IOSPATH := $(PATH):/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin

.PHONY: build force mesabuild pdf style stylereport hook test batchtest cover clean distclean

build:
	$(PYTHON) setup.py build_ext --inplace

force:
	$(PYTHON) setup.py build_ext --inplace -f

mesabuild:
	/usr/bin/env USE_MESAGL=1 $(PYTHON) setup.py build_ext --inplace

ios:
	-ln -s $(KIVYIOSROOT)/Python-2.7.1/python
	-ln -s $(KIVYIOSROOT)/Python-2.7.1/python.exe

	-rm -rdf iosbuild/
	mkdir iosbuild

	echo "First build ========================================"
	-PATH="$(IOSPATH)" $(HOSTPYTHON) setup.py build_ext -g
	echo "cythoning =========================================="
	find . -name *.pyx -exec cython -t {} \;
	echo "Second build ======================================="
	PATH="$(IOSPATH)" $(HOSTPYTHON) setup.py build_ext -g
	PATH="$(IOSPATH)" $(HOSTPYTHON) setup.py install -O2 --root iosbuild
	# Strip away the large stuff
	find iosbuild/ | grep -E '*\.(py|pyc|so\.o|so\.a|so\.libs)$$' | xargs rm
	-rm -rdf "$(BUILDROOT)/python/lib/python2.7/site-packages/kivy"
	# Copy to python for iOS installation
	cp -R "iosbuild/usr/local/lib/python2.7/site-packages/kivy" "$(BUILDROOT)/python/lib/python2.7/site-packages"

pdf:
	$(MAKE) -C doc latex && make -C doc/build/latex all-pdf

html:
	$(MAKE) -C doc html

style:
	$(PYTHON) $(CHECKSCRIPT) $(KIVY_DIR)

stylereport:
	$(PYTHON) $(CHECKSCRIPT) -html $(KIVY_DIR)

hook:
	# Install pre-commit git hook to check your changes for styleguide
	# consistency.
	cp kivy/tools/pep8checker/pre-commit.githook .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit

test:
	-rm -rf kivy/tests/build
	nosetests kivy/tests

batchtest:
	-rm -rf kivy/tests/build
	nosetests kivy/tests

cover:
	coverage html --include='$(KIVY_DIR)*' --omit '$(KIVY_DIR)data/*,$(KIVY_DIR)lib/*,$(KIVY_DIR)tools/*,$(KIVY_DIR)tests/*'

install:
	python setup.py install
clean:
	-rm -rf doc/build
	-rm -rf build
	-rm -rf htmlcov
	-rm .coverage
	-rm .noseids
	-rm -rf kivy/tests/build
	-find kivy -iname '*.pyc' -exec rm {} \;
	-find kivy -iname '*.pyo' -exec rm {} \;

distclean: clean
	-git clean -dxf
