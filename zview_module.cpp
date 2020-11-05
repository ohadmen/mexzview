#include <windows.h>
#include "mex.h"
#include <string>
#include "include/zview_inf.h"
#include <tuple>

extern "C" ZviewInf *__cdecl create_zviewinf();

#define ELIF_(cmd_name) \
    else if (cmd == #cmd_name) { func_##cmd_name(nlhs, plhs, nrhs, prhs); }
#define CLASS_SIGNITURE 0xd1d1

//--------UTILITY FUNCS----------
int64_t getKeyFromMxarray(const mxArray *arr[], int i)
{
    if (mxGetClassID(arr[i]) != mxINT64_CLASS)
        mexErrMsgTxt(("Expected int64 argument at location " + std::to_string(i)).c_str());
    int64_t key = *(int64_t *)mxGetData(arr[i]);
    return key;
}

template <class T, size_t nrows>
std::tuple<T *, size_t> getMatrixFromMxarray(const mxArray *arr[], int i)
{
    if (mxGetClassID(arr[i]) != getMXtype<T>())
        mexErrMsgTxt(("Expected class " + std::to_string(getMXtype<T>()) + " matrix at location " + std::to_string(i)).c_str());
    if (mxGetM(arr[i]) != nrows)
        mexErrMsgTxt(("Exptect " + std::to_string(nrows) + " rows(got " + std::to_string(mxGetM(arr[i])) + ")").c_str());
    size_t npts = mxGetN(arr[i]);
    T *ptsdata = (T *)mxGetData(arr[i]);
    return {ptsdata, npts};
}
std::tuple<float *, size_t> getColorPointsFromMxarray(const mxArray *arr[], int i)
{
    if (!mxIsSingle(arr[i]))
        mexErrMsgTxt(("Expected float matrix at location " + std::to_string(i)).c_str());
    if (mxGetM(arr[i]) != 6)
        mexErrMsgTxt("Matrix should be 6xN");
    size_t npts = mxGetN(arr[i]);
    float *ptsdata = (float *)mxGetData(arr[i]);
    return {ptsdata, npts};
}

std::string getString(const mxArray *arr[], int i)
{
    if (!mxIsChar(arr[i]))
        mexErrMsgTxt(("Expected string argument at location " + std::to_string(i)).c_str());
    std::string str(mxArrayToString(arr[i]));
    return str;
}

template <typename T>
mxClassID getMXtype() { return mxUNKNOWN_CLASS; }
template <>
mxClassID getMXtype<float>() { return mxSINGLE_CLASS; }
template <>
mxClassID getMXtype<int32_t>() { return mxINT32_CLASS; }
template <>
mxClassID getMXtype<uint32_t>() { return mxUINT32_CLASS; }
template <>
mxClassID getMXtype<int64_t>() { return mxINT64_CLASS; }
template <>
mxClassID getMXtype<uint64_t>() { return mxUINT64_CLASS; }
template <>
mxClassID getMXtype<bool>() { return mxLOGICAL_CLASS; }

template <class T>
void setScalarOutput(const T &val, mxArray *&mxout)
{

    mxout = mxCreateNumericMatrix(1, 1, getMXtype<T>(), mxREAL);
    *((T *)mxGetData(mxout)) = val;
}
//-------------------------

class ZviewInfWrapper
{
    const uint32_t m_classSigniture = CLASS_SIGNITURE;
    ZviewInf *m_zv;

public:
    ZviewInfWrapper() : m_zv(create_zviewinf()) {}
    ~ZviewInfWrapper()
    {
        m_zv->destroy();
        m_zv = nullptr;
    }
    bool isValid() const { return m_classSigniture == CLASS_SIGNITURE; }

    ZviewInf *getZviewPtr() const { return m_zv; }
    static ZviewInfWrapper *getFromMxarray(const mxArray *in)
    {
        if (mxGetNumberOfElements(in) != 1 || mxGetClassID(in) != mxUINT64_CLASS || mxIsComplex(in))
            mexErrMsgTxt("Input must be a real uint64 scalar.");
        ZviewInfWrapper *ptr = reinterpret_cast<ZviewInfWrapper *>(*((uint64_t *)mxGetData(in)));
        if (!ptr->isValid())
            mexErrMsgTxt("Handle not valid.");
        return ptr;
    }
};

void func_new(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 1)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInfWrapper *zv = new ZviewInfWrapper();
    setScalarOutput(reinterpret_cast<uint64_t>(zv), plhs[0]);
}

void func_delete(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 2)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    auto zvw = ZviewInfWrapper::getFromMxarray(prhs[1]);
    delete zvw;
}

void func_addColoredPoints(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    if (nrhs != 4)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    std::string name = getString(prhs, 2);
    auto [ptsdata, npts] = getMatrixFromMxarray<float, 4>(prhs, 3);

    int64_t key = zv->addColoredPoints(name.c_str(), npts, ptsdata);
    setScalarOutput(key, plhs[0]);
}

void func_getLastKeyStroke(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 2)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    int64_t key = zv->getLastKeyStroke();
    setScalarOutput(key, plhs[0]);
}
void func_savePly(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 3)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }

    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    std::string fn = getString(prhs, 2);
    bool ok = zv->savePly(fn.c_str());
    setScalarOutput(ok, plhs[0]);
}

void func_updateColoredPoints(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 4)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    auto key = getKeyFromMxarray(prhs, 2);
    auto [ptsdata, npts] = getMatrixFromMxarray<float, 4>(prhs, 3);
    bool ok = zv->updateColoredPoints(int(key), npts, ptsdata);
    setScalarOutput(ok, plhs[0]);
}
void func_addColoredMesh(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 5)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    std::string name = getString(prhs, 2);
    auto [ptsdata, npts] = getMatrixFromMxarray<float, 4>(prhs, 3);
    auto [facedata, nfaces] = getMatrixFromMxarray<int, 3>(prhs, 4);

    int64_t key = zv->addColoredMesh(name.c_str(), npts, ptsdata, nfaces, facedata);
    setScalarOutput(key, plhs[0]);
}
void func_addColoredEdges(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 5)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    std::string name = getString(prhs, 2);
    auto [ptsdata, npts] = getMatrixFromMxarray<float, 4>(prhs, 3);
    auto [edgesdata, nedges] = getMatrixFromMxarray<int, 3>(prhs, 4);

    int64_t key = zv->addColoredEdges(name.c_str(), npts, ptsdata, nedges, edgesdata);
    setScalarOutput(key, plhs[0]);
}
void func_loadFile(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 3)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    std::string filename = getString(prhs, 2);
    bool ok = zv->loadFile(filename.c_str());
    setScalarOutput(ok, plhs[0]);
}
void func_removeShape(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 3)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    auto key = getKeyFromMxarray(prhs, 2);
    bool ok = zv->removeShape(int(key));
    setScalarOutput(ok, plhs[0]);
}
void func_setCameraLookAt(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 5)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    auto [ep, ne] = getMatrixFromMxarray<float, 3>(prhs, 2);
    auto [cp, nc] = getMatrixFromMxarray<float, 3>(prhs, 3);
    auto [up, nu] = getMatrixFromMxarray<float, 3>(prhs, 4);
    bool ok = zv->setCameraLookAt(ep[0], ep[1], ep[2], cp[0], cp[1], cp[2], up[0], up[1], up[2]);
    setScalarOutput(ok, plhs[0]);
}
void func_getHandleNumFromString(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 3)
    {
        mexErrMsgTxt("Bad number of input arguments");
    }
    ZviewInf *zv = ZviewInfWrapper::getFromMxarray(prhs[1])->getZviewPtr();
    std::string name = getString(prhs, 2);
    int64_t key  = zv->getHandleNumFromString(name.c_str());
    setScalarOutput(key, plhs[0]);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Get the command string
    if (nrhs < 1 || !mxIsChar(prhs[0]))
        mexErrMsgTxt("First input should be a command string");
    std::string cmd(mxArrayToString(prhs[0]));
    if (0)
    { /*tidy*/
    }
    ELIF_(new)
    ELIF_(delete)
    ELIF_(addColoredPoints)
    ELIF_(getLastKeyStroke)
    ELIF_(savePly)
    ELIF_(updateColoredPoints)
    ELIF_(addColoredMesh)
    ELIF_(addColoredEdges)
    ELIF_(loadFile)
    ELIF_(removeShape)
    ELIF_(setCameraLookAt)
    ELIF_(getHandleNumFromString)
    else
    {
        mexErrMsgTxt(("unknown command " + cmd).c_str());
    }
}