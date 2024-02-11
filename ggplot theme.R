library(ggplot2)
theme_set(theme_bw() +
            theme(
              plot.title=element_text(face="bold", hjust=0.5, size=20),
              plot.subtitle=element_text(hjust=0.5, size=16),
              axis.title.x=element_text(face="bold",vjust=-2, size=16),
              axis.title.y=element_text(face="bold",vjust=5, size=16),
              axis.text.y = element_text(size=16),
              axis.text.x = element_text(size=16),
              plot.caption = element_text(size = 12, vjust = -5),
              plot.margin=margin(t=10, r=5, b=20, l=20),
              legend.text = element_text(size=12),
              legend.title=element_text(size=16, face="bold", hjust=0.5),
              legend.background = element_rect(fill="white", linewidth =1, linetype="solid", color="black"),
              panel.border = element_blank(),
              panel.grid.minor = element_blank(),
              axis.line = element_line(color = "black")))
