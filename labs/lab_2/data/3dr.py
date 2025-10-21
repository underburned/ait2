import os
import subprocess
import sys
from PIL import Image

# Indicate the openMVG and openMVS binary directories
OPENMVG_BIN = "/usr/local/bin/"
OPENMVS_BIN = "/usr/local/bin/OpenMVS/"

os.environ['LD_LIBRARY_PATH'] = "/usr/local/OpenCV-4.8.0/lib/"

# Indicate the openMVG camera sensor width directory
CAMERA_SENSOR_WIDTH_DIRECTORY = "/usr/local/lib/openMVG/"

DEBUG = False

# HELPERS for terminal colors
BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE = range(8)
NO_EFFECT, BOLD, UNDERLINE, BLINK, INVERSE, HIDDEN = (0, 1, 4, 5, 7, 8)


# from Python cookbook, #475186
def has_colours(stream):
    if not hasattr(stream, "isatty"):
        return False
    if not stream.isatty():
        return False  # auto color only on TTYs
    try:
        import curses
        curses.setupterm()
        return curses.tigetnum("colors") > 2
    except:
        # guess false in case of error
        return False


has_colours = has_colours(sys.stdout)


def printout(text, colour=WHITE, background=BLACK, effect=NO_EFFECT):
    if has_colours:
        seq = "\x1b[%d;%d;%dm" % (effect, 30 + colour, 40 + background) + text + "\x1b[0m"
        sys.stdout.write(seq + '\r\n')
    else:
        sys.stdout.write(text + '\r\n')


# OBJECTS to store config and data in

class ConfContainer(object):
    """Container for all the config variables"""
    pass


conf = ConfContainer()


class Step:
    def __init__(self, info, cmd, opt):
        self.info = info
        self.cmd = cmd
        self.opt = opt


class StepsStore:
    def __init__(self):
        self.steps_data = [
            ["Intrinsics analysis",
             os.path.join(OPENMVG_BIN, "openMVG_main_SfMInit_ImageListing"),
             ["-i", "%input_dir%", "-o", "%matches_dir%", "-d", "%camera_file_params%", "-k",
              "%width%;0;%width%;0;%width%;%heigth%;0;0;1"]],
            ["Compute features",
             os.path.join(OPENMVG_BIN, "openMVG_main_ComputeFeatures"),
             ["-i", "%matches_dir%/sfm_data.json", "-o", "%matches_dir%", "-m", "SIFT", "-p", "NORMAL", "-n", "10"]],
            ["Compute matching pairs",
             os.path.join(OPENMVG_BIN, "openMVG_main_PairGenerator"),
             ["-i", "%matches_dir%/sfm_data.json", "-o", "%matches_dir%" + "/pairs.bin"]],
            ["Compute matches",
             os.path.join(OPENMVG_BIN, "openMVG_main_ComputeMatches"),
             ["-i", "%matches_dir%/sfm_data.json", "-p", "%matches_dir%" + "/pairs.bin", "-o",
              "%matches_dir%" + "/matches.putative.bin"]],
            ["Filter matches",
             os.path.join(OPENMVG_BIN, "openMVG_main_GeometricFilter"),
             ["-i", "%matches_dir%/sfm_data.json", "-m", "%matches_dir%" + "/matches.putative.bin", "-g", "f", "-o",
              "%matches_dir%" + "/matches.f.bin"]],
            ["Sequential/Incremental reconstruction",
             os.path.join(OPENMVG_BIN, "openMVG_main_SfM"),
             ["-s", "INCREMENTAL", "-i", "%matches_dir%/sfm_data.json", "-m", "%matches_dir%", "-o",
              "%reconstruction_dir%"]],
            ["Colorize Structure",
             os.path.join(OPENMVG_BIN, "openMVG_main_ComputeSfM_DataColor"),
             ["-i", "%reconstruction_dir%/sfm_data.bin", "-o", "%reconstruction_dir%/colorized.ply"]],
            ["Structure from Known Poses",
             os.path.join(OPENMVG_BIN, "openMVG_main_ComputeStructureFromKnownPoses"),
             ["-i", "%reconstruction_dir%/sfm_data.bin", "-m", "%matches_dir%", "-f", "%matches_dir%/matches.f.bin",
              "-o", "%reconstruction_dir%/robust.bin"]],
            ["Colorized robust triangulation",
             os.path.join(OPENMVG_BIN, "openMVG_main_ComputeSfM_DataColor"),
             ["-i", "%reconstruction_dir%/robust.bin", "-o", "%reconstruction_dir%/robust_colorized.ply"]],
            ["Export to openMVS",
             os.path.join(OPENMVG_BIN, "openMVG_main_openMVG2openMVS"),
             ["-i", "%reconstruction_dir%/sfm_data.bin", "-o", "%mvs_dir%/scene.mvs", "-d", "%mvs_dir%"]],
            ["Densify point cloud",
             os.path.join(OPENMVS_BIN, "DensifyPointCloud"),
             ["scene.mvs", "--cuda-device", "-1", "-w", "%mvs_dir%"]],
            ["Reconstruct the mesh",
             os.path.join(OPENMVS_BIN, "ReconstructMesh"),
             ["scene_dense.mvs", "--cuda-device", "-1", "-w", "%mvs_dir%"]],
            ["Refine the mesh",
             os.path.join(OPENMVS_BIN, "RefineMesh"),
             ["scene_dense_mesh.mvs", "--cuda-device", "-1", "--scales", "1", "--gradient-step", "25.05", "-w",
              "%mvs_dir%"]],
            ["Texture the mesh",
             os.path.join(OPENMVS_BIN, "TextureMesh"),
             ["scene_dense_mesh_refine.mvs", "--cuda-device", "-1", "-w", "%mvs_dir%"]]
        ]

    def __getitem__(self, idx):
        return Step(*self.steps_data[idx])

    def length(self):
        return len(self.steps_data)

    def apply_conf(self, conf):
        """ replace each %var% per conf.var value in steps data """
        for s in self.steps_data:
            o2 = []
            for o in s[2]:
                co = o.replace("%input_dir%", conf.input_dir)
                co = co.replace("%output_dir%", conf.output_dir)
                co = co.replace("%width%", conf.width)
                co = co.replace("%heigth%", conf.heigth)
                co = co.replace("%matches_dir%", conf.matches_dir)
                co = co.replace("%reconstruction_dir%", conf.reconstruction_dir)
                co = co.replace("%mvs_dir%", conf.mvs_dir)
                co = co.replace("%camera_file_params%", conf.camera_file_params)
                o2.append(co)
            s[2] = o2


steps = StepsStore()

# ARGS
import argparse

parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description="Photogrammetry reconstruction with these steps : \r\n" +
                "\r\n".join(("\t%i. %s\t %s" % (t, steps[t].info, steps[t].cmd) for t in range(steps.length())))
)
parser.add_argument('input_dir', help="the directory wich contains the pictures set.")
parser.add_argument('output_dir', help="the directory wich will contain the resulting files.")
parser.add_argument('-f', '--first_step', type=int, default=0, help="the first step to process")
parser.add_argument('-l', '--last_step', type=int, default=13, help="the last step to process")

group = parser.add_argument_group('Passthrough',
                                  description="Option to be passed to command lines (remove - in front of option names)\r\ne.g. --1 p ULTRA to use the ULTRA preset in openMVG_main_ComputeFeatures")
for n in range(steps.length()):
    group.add_argument('--' + str(n), nargs='+')

parser.parse_args(namespace=conf)  # store args in the ConfContainer


# FOLDERS

def mkdir_ine(dirname):
    """Create the folder if not presents"""
    if not os.path.exists(dirname):
        os.mkdir(dirname)


# Absolute path for input and output dirs
conf.input_dir = os.path.abspath(conf.input_dir)
conf.output_dir = os.path.abspath(conf.output_dir)

if not os.path.exists(conf.input_dir):
    sys.exit("%s : path not found" % conf.input_dir)

###########
files = os.listdir(conf.input_dir)
im = Image.open(conf.input_dir + "/" + files[0])
(width, height) = im.size

conf.width = str(width / 2)
conf.heigth = str(height / 2)
###########
conf.matches_dir = os.path.join(conf.output_dir, "matches")
conf.reconstruction_dir = os.path.join(conf.output_dir, "reconstruction_global")
conf.mvs_dir = os.path.join(conf.output_dir, "mvs")
conf.camera_file_params = os.path.join(CAMERA_SENSOR_WIDTH_DIRECTORY, "sensor_width_camera_database.txt")

mkdir_ine(conf.output_dir)
mkdir_ine(conf.matches_dir)
mkdir_ine(conf.reconstruction_dir)
mkdir_ine(conf.mvs_dir)

steps.apply_conf(conf)

# WALK
print("# Using input dir  :  %s" % conf.input_dir)
print("#       output_dir :  %s" % conf.output_dir)
print("# First step  :  %i" % conf.first_step)
print("# Last step :  %i" % conf.last_step)
for cstep in range(conf.first_step, conf.last_step + 1):
    printout("#%i. %s" % (cstep, steps[cstep].info), effect=INVERSE)

    opt = getattr(conf, str(cstep))
    if opt is not None:
        # add - sign to short options and -- to long ones
        for o in range(0, len(opt), 2):
            if len(opt[o]) > 1:
                opt[o] = '-' + opt[o]
            opt[o] = '-' + opt[o]
    else:
        opt = []

    # Remove steps[cstep].opt options now defined in opt
    for anOpt in steps[cstep].opt:
        if anOpt in opt:
            idx = steps[cstep].opt.index(anOpt)
            if DEBUG:
                print('#\t' + 'Remove ' + str(anOpt) + ' from defaults options at id ' + str(idx))
            del steps[cstep].opt[idx:idx + 2]

    cmdline = [steps[cstep].cmd] + steps[cstep].opt + opt

    if not DEBUG:
        pStep = subprocess.Popen(cmdline)
        pStep.wait()
    else:
        print('\t' + ' '.join(cmdline))
