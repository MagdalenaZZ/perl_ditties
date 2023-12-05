





bsub.py -q basement 10 test3 python ~/bin/oases_0.2.08/scripts/oases_pipeline.py --data="-fastq -shortPaired -separate test_1.fastq test_2.fastq" --options="-ins_length 100 -unused_reads yes " --clean --kmin=27  --kmax=29 --kstep=2 --merge=27 --output=k27


bsub.py -q hugemem 60 3224 python ~/bin/oases_0.2.08/scripts/oases_pipeline.py --data="-fastq -shortPaired -separate 3224_1.CORR31_3_1.fastq 3224_1.CORR31_3_2.fastq -short 3224_1.CORR31_3SE.fastq" --options="-ins_length 205 -unused_reads yes " --clean --kmin=19 --kmax=31 --kstep=2 --merge=27 --output=3224_merge27




