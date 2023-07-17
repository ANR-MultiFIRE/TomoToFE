# source spam/bin/activate
# cd ../../../../../../../../../mnt/c/Users/homeuser/Desktop/Postdoc/FEniCS/MFront/Github_repoUrgent
# python3 Labelling.py


import tifffile
import numpy
import matplotlib.pyplot as plt
import spam.label
import spam.label.label as ltk
import spam.plotting.particleSizeDistribution as psd

binary = tifffile.imread("AggregatesOnly.tif")

labelled_total = spam.label.watershed(binary)
tifffile.imsave('labelled_total.tiff',labelled_total)

volumes = ltk.volumes(labelled_total)

# Removing small aggregates
SmallParticles = numpy.where(volumes < 17229) #17229 = sphere volume of a 4mm agg / voxel volume
labelled_big = ltk.removeLabels(labelled_total, SmallParticles)
labelled_big = ltk.makeLabelsSequential(labelled_big)
tifffile.imsave('labelledBigAgg.tiff',labelled_big)

# Removing big aggregates
BigParticles = numpy.where(volumes > 17229) #17229 = sphere volume of a 4mm agg / voxel volume
labelled_small = ltk.removeLabels(labelled_total, BigParticles)
labelled_small = ltk.makeLabelsSequential(labelled_small)
tifffile.imsave('labelledSmallAgg.tiff',labelled_small)
