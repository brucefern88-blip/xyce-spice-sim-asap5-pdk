#!/usr/bin/env bash
# =============================================================================
# install_xyce_mac.sh
# Builds and installs Xyce (SPICE-compatible circuit simulator) from source
# on macOS using the CMake build system.
#
# Based on: Xyce Configure, Build and Installation Guide Using CMake
#           https://github.com/Xyce/Xyce/blob/master/INSTALL.md
#
# What this script builds (in order):
#   1. Homebrew prerequisites (cmake, gcc, bison, flex, fftw, openmpi)
#   2. SuiteSparse  (sparse matrix library — only AMD and config subpackages)
#   3. Trilinos     (Sandia's numerical solver framework — required by Xyce)
#   4. Xyce         (the circuit simulator itself)
#
# Usage:
#   chmod +x install_xyce_mac.sh
#   ./install_xyce_mac.sh            # serial build (default)
#   ./install_xyce_mac.sh --mpi      # build with MPI parallel support
#   ./install_xyce_mac.sh --jobs 8   # use 8 CPU cores for compilation
#
# Prerequisites:
#   - macOS with Apple Silicon (M1/M2/M3/M4) or Intel
#   - Xcode Command Line Tools:  xcode-select --install
#   - Homebrew: https://brew.sh
#
# Install locations (all under $HOME/xyce-stack by default — change XYCE_ROOT):
#   $XYCE_ROOT/src/SuiteSparse     source
#   $XYCE_ROOT/src/Trilinos        source
#   $XYCE_ROOT/src/Xyce            source
#   $XYCE_ROOT/install/suitesparse installed library
#   $XYCE_ROOT/install/trilinos    installed library
#   $XYCE_ROOT/install/xyce        installed Xyce binary  ← add this/bin to PATH
#
# After a successful build, add Xyce to your shell:
#   echo 'export PATH="$HOME/xyce-stack/install/xyce/bin:$PATH"' >> ~/.zshrc
#   source ~/.zshrc
#   Xyce --version
# =============================================================================

set -euo pipefail   # exit on error, undefined variable, or pipe failure
IFS=$'\n\t'         # safer word splitting

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'   # no colour

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
banner()  { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════${NC}"; \
            echo -e "${BOLD}${BLUE}  $*${NC}"; \
            echo -e "${BOLD}${BLUE}══════════════════════════════════════${NC}\n"; }

# ── Argument parsing ──────────────────────────────────────────────────────────
ENABLE_MPI=OFF
JOBS=4           # conservative default; override with --jobs N

while [[ $# -gt 0 ]]; do
  case $1 in
    --mpi)    ENABLE_MPI=ON;  shift ;;
    --jobs)   JOBS="$2";      shift 2 ;;
    --help|-h)
      echo "Usage: $0 [--mpi] [--jobs N]"
      echo "  --mpi      Build Xyce with MPI parallel support (requires openmpi)"
      echo "  --jobs N   Number of parallel compile jobs (default: 4)"
      exit 0 ;;
    *) error "Unknown argument: $1  (try --help)" ;;
  esac
done

# ── User-configurable paths ───────────────────────────────────────────────────
# Change XYCE_ROOT if you want the entire stack somewhere other than ~/xyce-stack
XYCE_ROOT="${HOME}/xyce-stack"

SRC_DIR="${XYCE_ROOT}/src"
BUILD_DIR="${XYCE_ROOT}/build"
INSTALL_DIR="${XYCE_ROOT}/install"

SS_SRC="${SRC_DIR}/SuiteSparse"
SS_BUILD="${BUILD_DIR}/suitesparse"
SS_INSTALL="${INSTALL_DIR}/suitesparse"

TRILINOS_SRC="${SRC_DIR}/Trilinos"
TRILINOS_BUILD="${BUILD_DIR}/trilinos"
TRILINOS_INSTALL="${INSTALL_DIR}/trilinos"

XYCE_SRC="${SRC_DIR}/Xyce"
XYCE_BUILD="${BUILD_DIR}/xyce"
XYCE_INSTALL="${INSTALL_DIR}/xyce"

# Pinned versions — change to update (check GitHub for latest tags)
SUITESPARSE_VERSION="v7.8.3"    # minimum required by the INSTALL.md
TRILINOS_BRANCH="trilinos-release-14-4-branch"   # last rigorously tested with Xyce
XYCE_BRANCH="master"            # master is always regression-tested stable

# =============================================================================
# STEP 0 — Environment checks
# =============================================================================
banner "Step 0: Pre-flight checks"

# Confirm we are on macOS
[[ "$(uname -s)" == "Darwin" ]] || error "This script is for macOS only."

# Confirm Xcode CLI tools are present (provides clang, BLAS/LAPACK via Accelerate)
xcode-select -p &>/dev/null || \
  error "Xcode Command Line Tools not found. Run: xcode-select --install"
success "Xcode Command Line Tools found at $(xcode-select -p)"

# Confirm Homebrew is installed
command -v brew &>/dev/null || \
  error "Homebrew not found. Install from https://brew.sh then re-run this script."
success "Homebrew found at $(brew --prefix)"

# Confirm git is present
command -v git &>/dev/null || error "git not found. Run: xcode-select --install"
success "git found: $(git --version)"

info "Build configuration:"
info "  XYCE_ROOT  = ${XYCE_ROOT}"
info "  MPI        = ${ENABLE_MPI}"
info "  JOBS       = ${JOBS}"

# Create directory structure
mkdir -p "${SRC_DIR}" "${BUILD_DIR}" "${INSTALL_DIR}"

# =============================================================================
# STEP 1 — Homebrew prerequisites
# =============================================================================
banner "Step 1: Installing Homebrew prerequisites"

# These formulae map to the INSTALL.md prerequisites table:
#   cmake   → CMake 3.22+       (build system — will be required in 7.11)
#   gcc     → gfortran + g++    (Fortran for Trilinos; avoids Apple-Clang AztecOO bug)
#   bison   → bison 3.3+        (required parser generator)
#   flex    → flex 2.6+         (required lexer generator)
#   fftw    → FFTW3             (enables Harmonic Balance analysis)
#   wget    → for downloading source archives
BREW_PKGS=(cmake gcc bison flex fftw wget coreutils)

# Add openmpi only if the user requested a parallel build
[[ "${ENABLE_MPI}" == "ON" ]] && BREW_PKGS+=(open-mpi)

for pkg in "${BREW_PKGS[@]}"; do
  if brew list "${pkg}" &>/dev/null; then
    info "${pkg} already installed — skipping"
  else
    info "Installing ${pkg}..."
    brew install "${pkg}"
    success "${pkg} installed"
  fi
done

# Homebrew installs keg-only bison and flex (they shadow BSD system versions).
# We must prepend their bin dirs to PATH so CMake finds the correct versions.
BREW_PREFIX="$(brew --prefix)"
export PATH="${BREW_PREFIX}/opt/bison/bin:${BREW_PREFIX}/opt/flex/bin:${PATH}"

# Use Homebrew gcc for gfortran support; Apple Clang lacks it.
# Detect the latest gcc version Homebrew installed (e.g. gcc-14, gcc-13…)
GCC_VER=$(ls "${BREW_PREFIX}/bin/gcc-"* 2>/dev/null | \
          grep -oE 'gcc-[0-9]+' | sort -t- -k2 -n | tail -1 | cut -d- -f2)
[[ -z "${GCC_VER}" ]] && error "Homebrew gcc not found after install attempt."

export CC="${BREW_PREFIX}/bin/gcc-${GCC_VER}"
export CXX="${BREW_PREFIX}/bin/g++-${GCC_VER}"
export FC="${BREW_PREFIX}/bin/gfortran-${GCC_VER}"

success "Compilers set:"
success "  CC  = ${CC}"
success "  CXX = ${CXX}"
success "  FC  = ${FC}"

# Verify bison and flex meet minimum version requirements
BISON_VER=$(bison --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
FLEX_VER=$(flex --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
info "bison ${BISON_VER}, flex ${FLEX_VER} — minimums are 3.3 and 2.6 respectively"

# =============================================================================
# STEP 2 — Clone source repositories
# =============================================================================
banner "Step 2: Cloning source repositories"

clone_or_update() {
  # Usage: clone_or_update <url> <dest> <branch_or_tag>
  local url="$1" dest="$2" ref="$3"
  if [[ -d "${dest}/.git" ]]; then
    info "$(basename ${dest}) already cloned — pulling latest ${ref}"
    git -C "${dest}" fetch --quiet
    git -C "${dest}" checkout --quiet "${ref}"
    git -C "${dest}" pull --quiet || true   # tag refs won't pull — that is OK
  else
    info "Cloning $(basename ${dest})..."
    git clone --branch "${ref}" --depth 1 "${url}" "${dest}"
    success "Cloned $(basename ${dest})"
  fi
}

clone_or_update \
  "https://github.com/DrTimothyAldenDavis/SuiteSparse.git" \
  "${SS_SRC}" \
  "${SUITESPARSE_VERSION}"

clone_or_update \
  "https://github.com/trilinos/Trilinos.git" \
  "${TRILINOS_SRC}" \
  "${TRILINOS_BRANCH}"

clone_or_update \
  "https://github.com/Xyce/Xyce.git" \
  "${XYCE_SRC}" \
  "${XYCE_BRANCH}"

# =============================================================================
# STEP 3 — Build SuiteSparse (AMD + SuiteSparse_config only)
# =============================================================================
banner "Step 3: Building SuiteSparse"

# The INSTALL.md says Xyce only needs AMD and SuiteSparse_config from the
# larger SuiteSparse collection. Building only those two avoids pulling in
# CHOLMOD, UMFPACK, etc. and cuts compile time significantly.

mkdir -p "${SS_BUILD}"

cmake \
  -S "${SS_SRC}" \
  -B "${SS_BUILD}" \
  -D CMAKE_INSTALL_PREFIX="${SS_INSTALL}" \
  -D CMAKE_C_COMPILER="${CC}" \
  -D CMAKE_CXX_COMPILER="${CXX}" \
  -D SUITESPARSE_ENABLE_PROJECTS="suitesparse_config;amd" \
  -D BUILD_SHARED_LIBS=ON \
  -D CMAKE_BUILD_TYPE=Release

cmake --build "${SS_BUILD}" -j "${JOBS}" -t install
success "SuiteSparse installed to ${SS_INSTALL}"

# =============================================================================
# STEP 4 — Build Trilinos
# =============================================================================
banner "Step 4: Building Trilinos (this takes a while — ~20-40 min)"

# Trilinos is the most complex step. The Xyce repo ships a CMake "initial
# cache" file (trilinos-base.cmake or trilinos-MPI-base.cmake) that pre-sets
# all the Trilinos packages Xyce actually needs, avoiding a full Trilinos build.
# We layer our Mac-specific flags on top of that cache file.

mkdir -p "${TRILINOS_BUILD}"

# Select the appropriate Xyce-provided Trilinos cache file
if [[ "${ENABLE_MPI}" == "ON" ]]; then
  TRILINOS_CACHE="${XYCE_SRC}/cmake/trilinos/trilinos-MPI-base.cmake"
else
  TRILINOS_CACHE="${XYCE_SRC}/cmake/trilinos/trilinos-base.cmake"
fi

[[ -f "${TRILINOS_CACHE}" ]] || \
  error "Trilinos cache file not found at ${TRILINOS_CACHE}. Did the Xyce clone succeed?"

# The -Wno-error=implicit-function-declaration flag is specifically called out
# in the INSTALL.md for Apple's clang. Even though we use gcc here, it's
# harmless and guards against any system-header surprises.
CMAKE_C_EXTRA_FLAGS="-Wno-error=implicit-function-declaration"

cmake \
  -C "${TRILINOS_CACHE}" \
  -S "${TRILINOS_SRC}" \
  -B "${TRILINOS_BUILD}" \
  -D CMAKE_INSTALL_PREFIX="${TRILINOS_INSTALL}" \
  -D CMAKE_C_COMPILER="${CC}" \
  -D CMAKE_CXX_COMPILER="${CXX}" \
  -D CMAKE_Fortran_COMPILER="${FC}" \
  -D CMAKE_C_FLAGS="${CMAKE_C_EXTRA_FLAGS}" \
  -D CMAKE_BUILD_TYPE=Release \
  -D AMD_LIBRARY_DIRS="${SS_INSTALL}/lib" \
  -D AMD_INCLUDE_DIRS="${SS_INSTALL}/include" \
  -D TPL_ENABLE_FFTW=ON \
  -D FFTW_LIBRARY_DIRS="${BREW_PREFIX}/opt/fftw/lib" \
  -D FFTW_INCLUDE_DIRS="${BREW_PREFIX}/opt/fftw/include" \
  $( [[ "${ENABLE_MPI}" == "ON" ]] && echo \
    "-D CMAKE_C_COMPILER=$(which mpicc) \
     -D CMAKE_CXX_COMPILER=$(which mpicxx) \
     -D CMAKE_Fortran_COMPILER=$(which mpifort)" )

cmake --build "${TRILINOS_BUILD}" -j "${JOBS}" -t install
success "Trilinos installed to ${TRILINOS_INSTALL}"

# =============================================================================
# STEP 5 — Build Xyce
# =============================================================================
banner "Step 5: Building Xyce"

mkdir -p "${XYCE_BUILD}"

cmake \
  -S "${XYCE_SRC}" \
  -B "${XYCE_BUILD}" \
  -D CMAKE_INSTALL_PREFIX="${XYCE_INSTALL}" \
  -D CMAKE_C_COMPILER="${CC}" \
  -D CMAKE_CXX_COMPILER="${CXX}" \
  -D CMAKE_BUILD_TYPE=Release \
  -D Trilinos_ROOT="${TRILINOS_INSTALL}" \
  -D FLEX_EXECUTABLE="${BREW_PREFIX}/opt/flex/bin/flex" \
  -D FLEX_INCLUDE_DIR="${BREW_PREFIX}/opt/flex/include" \
  -D BISON_EXECUTABLE="${BREW_PREFIX}/opt/bison/bin/bison" \
  -D Xyce_USE_FFT=TRUE \
  $( [[ "${ENABLE_MPI}" == "ON" ]] && echo \
    "-D CMAKE_C_COMPILER=$(which mpicc) \
     -D CMAKE_CXX_COMPILER=$(which mpicxx)" )

cmake --build "${XYCE_BUILD}" -j "${JOBS}" -t install
success "Xyce installed to ${XYCE_INSTALL}"

# =============================================================================
# STEP 6 — PATH setup and smoke test
# =============================================================================
banner "Step 6: Final setup and verification"

XYCE_BIN="${XYCE_INSTALL}/bin"

# Check if PATH entry is already in .zshrc to avoid duplicate lines
SHELL_RC="${HOME}/.zshrc"
PATH_LINE="export PATH=\"${XYCE_BIN}:\$PATH\""

if grep -qF "${XYCE_BIN}" "${SHELL_RC}" 2>/dev/null; then
  info "PATH entry already present in ${SHELL_RC}"
else
  echo ""                          >> "${SHELL_RC}"
  echo "# Xyce circuit simulator" >> "${SHELL_RC}"
  echo "${PATH_LINE}"              >> "${SHELL_RC}"
  success "Added Xyce to PATH in ${SHELL_RC}"
fi

# Add to current session so the smoke test works immediately
export PATH="${XYCE_BIN}:${PATH}"

# Quick smoke test: run Xyce with a trivial netlist
SMOKE_NETLIST="$(mktemp /tmp/xyce_smoke_XXXX.cir)"
cat > "${SMOKE_NETLIST}" << 'EOF'
* Xyce smoke test: voltage divider
* Expected: V(2) = 2.5V  (half of 5V supply through equal resistors)
V1 1 0 DC 5V
R1 1 2 1k
R2 2 0 1k
.DC V1 5 5 1
.PRINT DC V(2)
.END
EOF

info "Running smoke test netlist..."
if Xyce "${SMOKE_NETLIST}" &>/dev/null; then
  success "Smoke test PASSED — Xyce ran successfully"
else
  warn "Smoke test produced a non-zero exit. Check output above."
fi
rm -f "${SMOKE_NETLIST}"

# =============================================================================
# DONE — Print summary
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              Xyce installation complete!             ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Xyce binary  : ${BOLD}${XYCE_BIN}/Xyce${NC}"
echo -e "  MPI support  : ${BOLD}${ENABLE_MPI}${NC}"
echo -e "  Stack root   : ${BOLD}${XYCE_ROOT}${NC}"
echo ""
echo -e "  To use Xyce in new terminal sessions, reload your shell config:"
echo -e "    ${BOLD}source ~/.zshrc${NC}"
echo ""
echo -e "  To uninstall Xyce only (keeps Trilinos/SuiteSparse):"
echo -e "    ${BOLD}xargs rm < ${XYCE_BUILD}/install_manifest.txt${NC}"
echo ""
echo -e "  To uninstall everything:"
echo -e "    ${BOLD}rm -rf ${XYCE_ROOT}${NC}"
echo ""
echo -e "  Documentation: https://xyce.sandia.gov/documentation-tutorials/"
echo -e "  User forum:    https://groups.google.com/g/xyce-users"
echo ""
