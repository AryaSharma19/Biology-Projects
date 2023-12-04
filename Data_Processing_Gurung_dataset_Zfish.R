setwd("/proj/vbautchlab/users/arya/zebrafish_Gurung_dataset")

library(Seurat)
library(dplyr)
library(patchwork)
library(SeuratDisk)


#mcherry positive cells should be endothelial, however this was not the case
#clustering and marker analysis is still needed
mcherrypos <- Read10X_h5("data/GSM6138416_filtered_feature_bc_matrix_GFP+mCherry+.h5")
seurat_object <- CreateSeuratObject(mcherrypos, project = "Gurung_data_set",
                                    min.cells = 3, min.features = 200)

#how to change active ident
#Idents(entire_data_set) <- "orig.ident"

#standard seurat work flow, some parameters are from the paper
#others I set
seurat_object[["percent.mt"]] <- PercentageFeatureSet(seurat_object, pattern = "^MT-")

VlnPlot(seurat_object, features = c("nFeature_RNA", "nCount_RNA", "percent.mt"), ncol = 3)
seurat_object <- subset(seurat_object, subset = nFeature_RNA > 96 & nFeature_RNA < 5456 
                        & percent.mt < 10)
seurat_object <- subset(seurat_object, subset = nCount_RNA < 61000)
seurat_object <- NormalizeData(seurat_object, normalization.method = "LogNormalize", scale.factor = 10000)
seurat_object <- FindVariableFeatures(seurat_object, selection.method = "vst", nfeatures = 2000)
all.genes <- rownames(seurat_object)
seurat_object <- ScaleData(seurat_object, features = all.genes)
seurat_object <- RunPCA(seurat_object, features = VariableFeatures(object = seurat_object))
ElbowPlot(seurat_object)
seurat_object <- FindNeighbors(seurat_object, dims = 1:12)
seurat_object <- FindClusters(seurat_object, resolution = 0.5)
seurat_object <- RunUMAP(seurat_object, dims = 1:12)
seurat_object <- RunTSNE(seurat_object, dims = 1:12)
DimPlot(seurat_object, reduction = "umap", size = 2, label = TRUE)

FeaturePlot(seurat_object, features = cbind("cdh5", "pecam1", "kdr"),
            reduction = "umap")

seurat_object <- subset(seurat_object,
                        idents = cbind("0","1","2","4","5","6","7","11"))

seurat_object <- NormalizeData(seurat_object, normalization.method = "LogNormalize", scale.factor = 10000)
seurat_object <- FindVariableFeatures(seurat_object, selection.method = "vst", nfeatures = 2000)
all.genes <- rownames(seurat_object)
seurat_object <- ScaleData(seurat_object, features = all.genes)
seurat_object <- RunPCA(seurat_object, features = VariableFeatures(object = seurat_object))
ElbowPlot(seurat_object)
seurat_object <- FindNeighbors(seurat_object, dims = 1:10)
seurat_object <- FindClusters(seurat_object, resolution = 0.5)
seurat_object <- RunUMAP(seurat_object, dims = 1:10)
seurat_object <- RunTSNE(seurat_object, dims = 1:10)
DimPlot(seurat_object, reduction = "umap", size = 2, label = TRUE)

saveRDS(seurat_object, "RDSs/new_endothelials.rds")
seurat_object <- readRDS("RDSs/new_endothelials.rds")

markers <- FindAllMarkers(seurat_object)
markers <- markers[markers$p_val_adj < 0.05,]
markers <- markers[markers$avg_log2FC > 0.5 | markers$avg_log2FC < -0.5,]

#adding annotations to marker list
#https://satijalab.org/seurat/articles/visualization_vignette
#load variable annotations
load("/work/users/a/r/arya19/zebrafish_gene_names/zebrafish_gene_annos.RData")
markers_with_annos <- left_join(markers, 
                         annotations[, c(2, 3, 9)], 
                         by = c("gene" = "gene_name"),
                         multiple = "first")
write.csv(markers_with_annos, file = "markers/endothelial_markers")

seurat_object <- readRDS("RDSs/endothelials.rds")

seurat_object[["artven"]] <- NA 
seurat_object$artven[seurat_object$seurat_clusters == "0"] <- "Ven 1"
seurat_object$artven[seurat_object$seurat_clusters == "1"] <- "1"
seurat_object$artven[seurat_object$seurat_clusters == "2"] <- "Ven 2"
seurat_object$artven[seurat_object$seurat_clusters == "3"] <- "3"
seurat_object$artven[seurat_object$seurat_clusters == "4"] <- "Art 1"
seurat_object$artven[seurat_object$seurat_clusters == "5"] <- "Art 2"
seurat_object$artven[seurat_object$seurat_clusters == "6"] <- "Art 3"
seurat_object$artven[seurat_object$seurat_clusters == "7"] <- "Ven 3"
seurat_object$artven[seurat_object$seurat_clusters == "8"] <- "8"
seurat_object$artven[seurat_object$seurat_clusters == "9"] <- "Ven 5"
seurat_object$artven[seurat_object$seurat_clusters == "10"] <- "Ven 4"
seurat_object$artven[seurat_object$seurat_clusters == "11"] <- "11"

saveRDS(seurat_object, "RDSs/endothelials.rds")
