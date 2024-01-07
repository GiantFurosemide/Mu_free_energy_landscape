conda activate md-davis

# 1.data file

gro_file='example/md_protein.gro'
traj_file='example/md_protein.xtc'
#

# 2.processing

input_top=$gro_file
input_traj=$traj_file
temperature=300
tu='ps'

j_name='2dn2 enhance sampling'
rmds_file='rmsd_1.xvg'
rmds_out_plot='rmsd_1.html'
gyrate_file='gyrate_1.xvg'
gyrate_out_plot='gyrate_1.html'
rmsd_rg_file='rmsd_rg_1.xvg'
landscape_RMSD_out='landscape_RMSD_RG.html'
landscape_PCA_out='landscape_PCA.html'

pc1_file='pc1.xvg'
pc2_file='pc2.xvg'
pc1pc2_file='pc1pc2.xvg'
FES_xpm='FES_PCA.xpm'
gibbs_eps='gibbs_PCA.eps'
FES_xpm_rmsd_rg='FES_rmsd_rg.xpm'
gibbs_eps_rmsd_rg='gibbs_rmsd_rg.eps'



# make rmsd and gyrate file by C-alpha
echo 3 3 | gmx rms -f $input_traj -s $input_top -o $rmds_file -tu $tu
echo 3| gmx gyrate -f $input_traj -s $input_top -o $gyrate_file

# plot rmsd and gyrate
md-davis xvg $rmds_file -o $rmds_out_plot
md-davis xvg $gyrate_file -o $gyrate_out_plot

# landscape by rmsd and gyrate
# 确认过是300K
echo "processing landscape: RMSD and Rg"
md-davis landscape_xvg -c -T $temperature -x $rmds_file -y $gyrate_file -n $j_name -l "FEL for $j_name" --axis_labels  "{'x': 'RMSD (in nm)', 'y': 'Rg (in nm)', 'z': 'Free Energy (kJ mol<sup>-1</sup>)<br> '}" -o $landscape_RMSD_out
echo "Done!"

grep -v "[@#]" $rmds_file > temp && mv temp $rmds_file
grep -v "[@#]" $gyrate_file > temp && mv temp $gyrate_file
paste $rmds_file $gyrate_file  | awk '{print $1, $2, $4}' > $rmsd_rg_file
#Calculate Gibbs Free Energy
gmx sham -f $rmsd_rg_file -ls $FES_xpm_rmsd_rg -tsham $temperature -nlevels 50 -ngrid 100
#sed -i 's/PC1/RMSD(Cα)/g' $FES_xpm_rmsd_rg
#sed -i 's/PC2/Radius of Gyration(Cα)/g' $FES_xpm_rmsd_rg
awk '{gsub(/PC1/,"RMSD(C-alpha)"); gsub(/PC2/,"Radius of Gyration(C-alpha)"); print}' $FES_xpm_rmsd_rg > temp && mv temp $FES_xpm_rmsd_rg
gmx xpm2ps -f $FES_xpm_rmsd_rg -o $gibbs_eps_rmsd_rg -rainbow red



# landscape by PCA

#Calculate covariance matrix and calculate the eigenvectors and eigenvalues. default calculated by C-alpha
echo 3 3 | gmx covar -f $input_traj -s $input_top -o eigenvalues.xvg -v eigenvectors.trr -xpma covapic.xpm
#Calculate PC1 and PC2
echo 3 3 | gmx anaeig -f $input_traj -s $input_top -v eigenvectors.trr -last 1 -proj $pc1_file
echo 3 3 | gmx anaeig -f $input_traj -s $input_top -v eigenvectors.trr -first 2 -last 2 -proj $pc2_file
#Concatenate PC1 and PC2 in one file.
paste $pc1_file $pc2_file  | awk '{print $1, $2, $4}' > $pc1pc2_file
#Calculate Gibbs Free Energy
gmx sham -f $pc1pc2_file -ls $FES_xpm -tsham $temperature -nlevels 50 -ngrid 100
gmx xpm2ps -f $FES_xpm -o $gibbs_eps -rainbow red

echo "processing landscape: PC1 and PC2"
md-davis landscape_xvg -c -T $temperature -x $pc1_file -y $pc2_file -n $j_name -l "FEL for $j_name" --axis_labels  "{'x': 'PC1', 'y': 'PC2', 'z': 'Free Energy (kJ mol<sup>-1</sup>)<br> '}" -o $landscape_PCA_out
echo "Done!"

conda deactivate

echo "##################################################"
echo "Done!"
echo "3d Gibbs Free Energy landscape by RMSD and Rg: $landscape_RMSD_out"
echo "3d Gibbs Free Energy landscape by PCA: $landscape_PCA_out"
echo "2d Gibbs Free Energy landscape by RMSD and Rg: $gibbs_eps_rmsd_rg"
echo "2d Gibbs Free Energy landscape by PCA: $gibbs_eps"
echo "##################################################"
