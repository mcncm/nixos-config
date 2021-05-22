{ stdenv, python, buildPythonPackage, pythonOlder, fetchFromGitHub
, setuptoolsBuildHook, gcc, hypothesis, numpy, scipy, matplotlib, cython, pytest
}:

buildPythonPackage rec {
  pname = "qutip";
  version = "4.6.1";
  disabled = pythonOlder "3.5";

  src = fetchFromGitHub {
    owner = "qutip";
    repo = "qutip";
    rev = "v${version}";
    sha256 = "0nr0amk6k07rrx1r8a2vsw390cw9fqr0g4ian4rx0r4x9nqmjy57";
  };

  postPatch = ''
    substituteInPlace requirements.txt \
      --replace "cython>=0.21" "cython" \
      --replace "numpy>=1.12" "numpy" \
      --replace "scipy>=1.0" "scipy"
  '';

  propagatedBuildInputs = [ numpy scipy matplotlib cython ];

  nativeBuildInputs = [ numpy scipy cython pytest setuptoolsBuildHook ];

  enableParallelBuilding = true;

  buildPhase = ''
    ${python.interpreter} setup.py --with-openmp bdist_wheel
  '';

  doCheck = false;

  checkInputs = [ hypothesis ];

  checkPhase = ''
    runHook preCheck
    pushd dist
    ${python.interpreter} -c 'import qutip.testing as qt; qt.run()'
    popd
    runHook postCheck
  '';

  meta = with stdenv.lib; {
    description = "Quantum Toolbox in Python";
    homepage = "https://qutip.org";
    changelog = "http://qutip.org/docs/latest/changelog.html";
    license = licenses.bsd3;
    maintainers = with maintainers; [ mcncm ];
  };
}
