version 1.0

task DSS_DMR {
    input {
        File tumor_bed
        File normal_bed
        String pname
        Int threads
    }

    Float file_size = ceil(size(tumor_bed, "GB") + size(normal_bed, "GB") + 10)

    command <<<
        set -euxo pipefail

        # Extract methylation info from bed files for DSS
        cut -f1,2,6,7 ~{tumor_bed} > ~{basename(tumor_bed) + ".tmp"}
        cut -f1,2,6,7 ~{normal_bed} > ~{basename(normal_bed) + ".tmp"}

        # Run DSS
        Rscript --vanilla /app/DSS_tumor_normal.R \
            ~{basename(tumor_bed) + ".tmp"} \
            ~{basename(normal_bed) + ".tmp"} \
            ~{pname + ".DMR.tsv"} \
            ~{threads}

        rm -f ~{basename(tumor_bed) + ".tmp"} ~{basename(normal_bed) + ".tmp"}
    >>>

    output {
        File output_DMR = pname + ".DMR.tsv"
    }

    runtime {
        docker: "quay.io/pacbio/somatic_r_tools@sha256:c5e1820b3329e13c092149015d16764e8250755c85a72838dc6ce201b2fa6876"
        cpu: threads
        memory: "~{threads * 4} GB"
        disk: file_size + " GB"
        maxRetries: 2
        preemptible: 1
    }
}

task annotate_DMR {
    input {
        File DMR
        String pname
        Int threads
    }

    Float file_size = ceil(size(DMR, "GB"))

    command <<<
        set -euxo pipefail

        # Annotate DMRs
        Rscript --vanilla /app/annotatr_dmr.R \
            ~{DMR} \
            ~{pname} \
            ~{threads}
    >>>

    output {
        Array[File]+ output_DMR_annotated = glob(pname + "*.tsv.gz")
    }

    runtime {
        docker: "quay.io/pacbio/somatic_r_tools@sha256:c5e1820b3329e13c092149015d16764e8250755c85a72838dc6ce201b2fa6876"
        cpu: threads
        memory: "~{threads * 4} GB"
        disk: file_size + " GB"
        maxRetries: 2
        preemptible: 1
    }
}
