Cbind <- function(...) {    # See llist function with Hmisc label function
  dotlist <- list(...)
  if(is.matrix(dotlist[[1]])) {
	y <- dotlist[[1]]
	ynam <- dimnames(y)[[2]]
	if(!length(ynam))
	  stop('when first argument is a matrix it must have column dimnames')
	other <- y[,-1,drop= FALSE]
	return(structure(y[,1], class='Cbind', label=ynam[1], other=other))
  }
  lname <- names(dotlist)
  name <- vname <- as.character(sys.call())[-1]
  for(i in 1:length(dotlist)) {
        vname[i] <- if(length(lname)) lname[i] else ''
        ## Added length() and '' 12Jun01, remove length(vname[i])==0 below
        if(vname[i]=='') vname[i] <- name[i]
	  }

  lab <- attr(y <- dotlist[[1]],'label')
  if(!length(lab)) lab <- vname[1]
  if(!is.matrix(other <- dotlist[[2]]) || ncol(other)<2) {  #9Jan98
	other <- as.matrix(as.data.frame(dotlist))[,-1,drop= FALSE]
	dimnames(other)[[2]] <- vname[-1]
  }
  structure(y, class='Cbind', label=lab, other=other)
}

if(.R.) as.numeric.Cbind <- as.double.Cbind <- function(x, ...) x
# Keeps xyplot from stripping off "other" attribute in as.numeric

#c.Cbind <- function(...) {
#  res <- oth <- numeric(0)
#  for(a in list(...)) {
#    lab <- attr(a,'label')
#    res <- c(res, oldUnclass(a))
#    oth <- rbind(oth, attr(a,'other'))
#  }
#  structure(res, class='Cbind', label=lab, other=oth)
#}

'[.Cbind' <- function(x, ...) {
  structure(oldUnclass(x)[...], class='Cbind',
			label=attr(x,'label'),
			other=attr(x,'other')[...,,drop= FALSE])
}

prepanel.xYplot <- function(x, y, ...) {
  xlim <- range(x, na.rm=TRUE)
  ylim <- range(y, attr(y,'other'), na.rm=TRUE)
  list(xlim=xlim, ylim=ylim, dx=diff(xlim), dy=diff(ylim))
}

## MB add method="filled bands" 
## MB use col.fill to specify colors for filling bands
panel.xYplot <-
  function(x, y, subscripts, groups = NULL, 
           type = if(is.function(method) || method == "quantiles")
           "b" else "p", 
           method = c("bars", "bands", "upper bars", "lower bars", 
             "alt bars", "quantiles", "filled bands"), 
           methodArgs = NULL, label.curves = TRUE, abline, 
           probs = c(0.5, 0.25, 0.75), nx, cap = 0.015, lty.bar = 1, 
           lwd = plot.line$lwd, lty = plot.line$lty, 
           pch = plot.symbol$pch, cex = plot.symbol$cex, 
           font = plot.symbol$font, col = NULL, 
           lwd.bands = NULL, lty.bands = NULL, col.bands = NULL, 
           minor.ticks = NULL, col.fill = NULL, ...)
{
  if(missing(method) || !is.function(method))
    method <- match.arg(method)   # was just missing() 26Nov01
  type <- type   # evaluate type before method changes 9May01
  if(length(groups)) groups <- as.factor(groups)
  other <- attr(y, "other")
  if(length(other)) {
    nother <- ncol(other)
    if(nother == 1) {
      lower <- y - other
      upper <- y + other
    }
    else {
      lower <- other[, 1]
      upper <- other[, 2]
    }
  }
  else nother <- 0
  y <- oldUnclass(y)
  g <- as.integer(groups)[subscripts]
  ng <- if(length(groups)) max(g) else 1
  levnum <- if(length(groups)) sort(unique(g)) else 1
  if(is.function(method) || method == "quantiles") {
    ## 2Mar00
    if(!is.function(method)) {
      method <- quantile  # above: methodArgs=NULL
      if(!length(methodArgs))
        methodArgs <- list(probs = probs)
    }
    if(length(methodArgs))
      methodArgs$na.rm <- TRUE
    else methodArgs <- list(na.rm = TRUE)
    if(ng == 1) {
      if(missing(nx))
        nx <- min(length(x)/4, 40)    
      ## Next 2 lines 2Mar00
      xg <- if(nx)
        as.numeric(as.character(cut2(x, 
                                     m = nx, levels.mean = TRUE))) else x
      dsum <- do.call("summarize",
                      c(list(y, llist(xg = xg), method, type = "matrix", 
                             stat.name = "Z"), methodArgs))
    }
    else {
      xg <- x
      if(missing(nx) || nx)
        for(gg in levnum) {
          ## 2Mar00
          w <- g == gg
          if(missing(nx))
            nx <- min(sum(w)/4, 40)
          xg[w] <-
            as.numeric(as.character(cut2(xg[w], m = nx,
                                         levels.mean = TRUE)))
        }
      dsum <- do.call("summarize",
                      c(list(y, by = llist(g, xg),
                             method, type = "matrix", stat.name = "Z"), 
                        methodArgs))
      g <- dsum$g
      groups <- factor(g, 1:length(levels(groups)),
                       levels(groups))
      subscripts <- TRUE     ## 6Dec00
    }
    x <- dsum$xg
    y <- dsum$Z[, 1, drop = TRUE]
    other <- dsum$Z[, -1]
    nother <- 2
    method <- "bands"
  }
  plot.symbol <- trellis.par.get(if(ng > 1) "superpose.symbol"
   else "plot.symbol")
  plot.line <- trellis.par.get(if(ng > 1) "superpose.line"
   else "plot.line")
  ## MB 04/17/01 default colors for filled bands
  ## 'pastel' colors matching superpose.line$col
  plot.fill <- c(9, 10, 11, 12, 13, 15, 7) 
  ##The following is a fix of panel.xyplot to work for type='b'
  ppanel <- function(x, y, type, cex, pch, font, lwd, lty, col, ...) {
    ##      if(type == "l")   9May01
    gfun <- ordGridFun(.R.)
    if(type != 'p') gfun$lines(x, y, lwd = lwd, lty = lty, col = col, ...)
    ##rm type=type 9May01

    if(type !='l') gfun$points(x=x, y=y,
         ## size=if(.R.)unit(cex*2.5,"mm") else NULL,
         pch = pch, font = font, cex = cex, col = col, 
         type = type, lwd=lwd, lty=lty, ...)
  }

  ##The following is a fix for panel.superpose for type='b' 
  pspanel <- function(x, y, subscripts, groups, type, lwd, lty, 
                      pch, cex, font, col, ...) {
    gfun <- ordGridFun(.R.)
    
	groups <- as.numeric(groups)[subscripts]
	N <- seq(along = groups)
	for(i in sort(unique(groups))) {
	  which <- N[groups == i]	# j <- which[order(x[which])]	
										# sort in x
	  j <- which	# no sorting
	  if(type != "p") gfun$lines(x[j], y[j],
           col = col[i], lwd = lwd[i], lty = lty[i], 
           ...)  # remove type=type[i] 9May01

      if(type !='l') gfun$points(x[j], y[j],
           ## size=if(.R.) unit(cex[i]*2.5, 'mm') else NULL,
           col = col[i], pch = pch[i], cex = cex[i],
           font = font[i], lty=lty[i], lwd=lwd[i], ...)
	  ## S-Plus version used type=type[i]; was type=type for points()
	}
  }
  
  lty <- rep(lty, length = ng)
  lwd <- rep(lwd, length = ng)
  pch <- rep(pch, length = ng)
  cex <- rep(cex, length = ng)
  font <- rep(font, length = ng)
  if(!length(col))
    col <- if(type == "p") plot.symbol$col else 
   plot.line$col
  col <- rep(col, length = ng)
  ## 14Apr2001 MB changes: set colors for method = "filled bands"
  if(!length(col.fill))
    col.fill <- plot.fill
  col.fill <- rep(col.fill, length = ng)       
  ## end MB

  if(ng > 1) {
    ## MB 14Apr2001: if method == "filled bands"
    ## have to plot filled bands first, otherwise lines/symbols
    ## would be hidden by the filled band
    if(method == "filled bands") {
      gfun <- ordGridFun(.R.)
      for(gg in levnum) {
        s <- g == gg
        gfun$polygon(x = c(x[s], rev(x[s])),
                     y = c(lower[s], rev(upper[s])), col =  col.fill[gg])
      }
    }  ## end MB
    pspanel(x, y, subscripts, groups, lwd = lwd, lty = 
            lty, pch = pch, cex = cex, font = font, col
            = col, type = type)
    if(type != "p" && !(is.logical(label.curves) && !
         label.curves)) {
      lc <- if(is.logical(label.curves))
        list(lwd  = lwd, cex = cex[1]) else
      c(list(lwd = lwd, cex = cex[1]), label.curves)
      curves <- vector("list", length(levnum))
      names(curves) <- levels(groups)[levnum]  # added levnum 24Oct01
      i <- 0
      for(gg in levnum) {
        i <- i + 1
        s <- g == gg
        curves[[i]] <- list(x[s], y[s])
      }
      labcurve(curves, lty = lty[levnum], lwd = lwd[levnum],
               col = col[levnum], opts = lc, grid=TRUE, ...)
    }
  }
  ## MB 14Apr2001: if method == "filled bands"
  ## plot filled bands first, otherwise lines/symbols
  ## would be hidden by the filled band
  else {
    if(method == "filled bands") {
      if(.R.) grid.polygon(x = c(x, rev(x)), y = c(lower, rev(upper)),
                           gp=gpar(fill = col.fill),
                           default.units='native') else
      polygon(x = c(x, rev(x)), y = c(lower, rev(upper)), col = col.fill)
    } ## end MB
    ppanel(x, y, lwd = lwd, lty = lty, pch = pch, cex = cex,
           font = font, col = col, type = type)
  } 
  ## 14Apr2001 MB
  ## final change for filled bands: just skip the rest
  ## if method = filled bands, remaining columns of other are ignored

  if(nother && method != "filled bands") {
    if(method == "bands") {
      dob <- function(a, def, ng, j)
        {
          if(!length(a))
            return(def)
          if(!is.list(a))
            a <- list(a)
          a <- rep(a, length = ng)
          sapply(a, function(b, j)
                 b[j], j = j)
        }
      for(j in 1:ncol(other)) {
        if(ng == 1)
          ppanel(x, other[, j], 
                 lwd = dob(lwd.bands, lwd, ng, j),
                 lty = dob(lty.bands, lty, ng, j), 
                 col = dob(col.bands, col, ng, j), 
                 pch = pch, cex = cex, font = 
                 font, type = "l")
        else pspanel(x, other[, j], 
                     subscripts, groups, 
                     lwd = dob(lwd.bands, lwd, ng, j),
                     lty = dob(lty.bands, lty, ng, j), 
                     col = dob(col.bands, col, ng, j), 
                     pch = pch, cex = cex, font = 
                     font, type = "l")
      }
    }
    else {
      errbr <- function(x, y, lower, upper, cap, 
                        lty, lwd, col, connect)
        {
          gfun    <- ordGridFun(.R.) ## see Misc.s
          segmnts <- gfun$segments
          gun     <- gfun$unit
          
          smidge <- 0.5 * cap *
            (if(.R.)unit(1,'npc') else diff(par("usr" )[1:2]))
          switch(connect,
                 all = {
                   segmnts(x, lower, x, upper,
                           lty = lty, lwd = lwd, col = col)
                   segmnts(gun(x)-smidge, lower,
                           gun(x)+smidge, lower,
                           lwd = lwd, lty = 1, col = col)
                   segmnts(gun(x)-smidge, upper,
                           gun(x)+smidge, upper,
                           lwd = lwd, lty = 1, col = col)
                 }
                 ,
                 upper = {
                   segmnts(x, y, x, upper, lty = lty, lwd = lwd, col = col)
                   segmnts(gun(x)-smidge,  upper,
                           gun(x)+smidge,  upper,
                           lwd = lwd, lty = 1, col = col)
                 }
                 ,
                 lower = {
                   segmnts(x, y, x, lower, lty = lty, lwd = lwd, col = col)
                   segmnts(gun(x)-smidge,  lower,
                           gun(x)+smidge,  lower,
                           lwd = lwd, lty = 1, col = col)
                 }
                 )
        }
      if(ng == 1)
        errbr(x, y, lower, upper, cap, 
              lty.bar, lwd, col, switch(method,
                                        bars = "all",
                                        "upper bars" = "upper",
                                        "lower bars" = "lower",
                                        "alt bars" = "lower"))
      else {
        if(method == "alt bars")
          medy <- median(y, na.rm = TRUE)
        for(gg in levnum) {
          s <- g == gg
          connect <- switch(method,
                            bars = "all",
                            "upper bars" = "upper",
                            "lower bars" = "lower",
                            "alt bars" = if(median(y[s], 
                              na.rm = TRUE) > medy) "upper"
                            else "lower")
          errbr(x[s], y[s], lower = lower[s],
                upper = upper[s], cap, lty.bar, 
                lwd[gg], col[gg], connect)
        }
      }
    }
  }
  if(length(minor.ticks)) {
    minor.at <- if(is.list(minor.ticks)) minor.ticks$at
    else minor.ticks
    minor.labs <- if(is.list(minor.ticks) &&
                     length(minor.ticks$labels)) minor.ticks$labels
    else FALSE
    gfun$axis(side = 1, at = minor.at, labels = FALSE,
              tck = par("tck") * 0.5, outer = TRUE, cex = par("cex") * 
         0.5)
    if(!is.logical(minor.labs))
      gfun$axis(side = 1, at = minor.at, labels = 
                minor.labs, tck = 0, cex = par("cex") * 0.5, line = 1.25)
  }
  if(type != "l" && ng > 1) {
	##set up for key() if points plotted
    if(.R.) {
      Key <- function(x=0, y=1, lev, cex, col, font, pch, ...) {
        oldpar <- par(usr=c(0,1,0,1),xpd=NA)
        on.exit(par(oldpar))
        if(is.list(x)) { y <- x[[2]]; x <- x[[1]] }
        ## Even though par('usr') shows 0,1,0,1 after lattice draws
        ## its plot, it still needs resetting
        if(!length(x)) x <- 0
        if(!length(y)) y <- 1  ## because of formals()
        rlegend(x, y, legend=lev, cex=cex, col=col, pch=pch)
        invisible()
      }
 } else {
   Key <- function(x=NULL, y=NULL, lev, cex, col, font, pch, ... ) {
     if(length(x)) {
       if(is.list(x)) {
         y <- x$y
         x <- x$x
       }
       key(x = x, y = y, text = list(lev, col = col),
           points = list(cex = cex, col = col, font = font,
             pch = pch), transparent = TRUE, ...)
     }
     else key(text = list(lev, col = col),
              points  = list(cex = cex, col = col,
                font = font, pch = pch), transparent =
              TRUE, ...)
     invisible()
   }
 }
    formals(Key) <- list(x=NULL,y=NULL,lev=levels(groups), cex=cex,
                         col=col, font=font, pch=pch)  #, ...=NULL)
    storeTemp(Key)
  }
  if(!missing(abline))
    do.call("panel.abline", abline)
  if(type == "l" && ng > 1) {
    ## Set up for legend (key() or rlegend()) if lines drawn
    if(.R.) {
      Key <- function(x=0, y=1, lev, cex, col, lty, lwd, ...) {
        oldpar <- par(usr=c(0,1,0,1),xpd=NA)
        on.exit(par(oldpar))
        if(is.list(x)) { y <- x[[2]]; x <- x[[1]] }
        ## Even though par('usr') shows 0,1,0,1 after lattice draws
        ## its plot, it still needs resetting
        if(!length(x)) x <- 0
        if(!length(y)) y <- 1  ## because of formals()
        rlegend(x, y, legend=lev, cex=cex, col=col, lty=lty, lwd=lwd)
        invisible()
    }
 } else {
   Key <- function(x=NULL, y=NULL, lev, col, lty, lwd, ...)
     {
       if(length(x)) {
         if(is.list(x)) {
           y <- x$y
           x <- x$x
         }
         key(x = x, y = y,
             text = list(lev, col = col),
             lines = list(col = col, lty = lty, lwd = lwd),
             transparent  = TRUE, ...)
       }
       else key(text = list(lev, col = col),
                lines = list(col = col, lty = lty, lwd = lwd),
                transparent = TRUE, ...)
       invisible()
     }
 }
    formals(Key) <- list(x=NULL,y=NULL,lev=levels(groups), col=col,
                         lty=lty, lwd=lwd)  #, ...=NULL)
    storeTemp(Key)
  }
}

xYplot <- if(.R.)
  function (formula, data=sys.frame(sys.parent()),
            groups, subset,
            xlab=NULL, ylab=NULL, ylim=NULL,
            panel=panel.xYplot, prepanel=prepanel.xYplot,
            scales=NULL, minor.ticks=NULL, ...) {

    require('grid')
  require('lattice')
  yvname <- as.character(formula[2])  # tried deparse
  y <- eval(parse(text=yvname), data)
  if(!length(ylab)) ylab <- label(y, units=TRUE, plot=TRUE,
                                  default=yvname, grid=TRUE)
#    ylab <- attr(y, 'label')  26sep02
#    if(!length(ylab)) ylab <- yvname
#  }
  if(!length(ylim)) {
    yother <- attr(y,'other')
    if(length(yother)) ylim <- range(y, yother, na.rm=TRUE)
  }

  xvname <- formula[[3]]
  if(length(xvname)>1 && as.character(xvname[[1]])=='|') 
    xvname <- xvname[[2]]  # ignore conditioning var
  xv <- eval(xvname, data)
  if(!length(xlab)) xlab <- label(xv, units=TRUE, plot=TRUE,
                                  default=as.character(xvname),
                                  grid=TRUE)
#    xlab <- attr(xv, 'label') 26sep02
#    if(!length(xlab)) xlab <- as.character(xvname)
#  }

  if(!length(scales$x)) {
    if(length(maj <- attr(xv,'scales.major'))) scales$x <- maj
  }
  if(!length(minor.ticks)) {
    if(length(minor <- attr(xv,'scales.minor'))) minor.ticks <- minor
  }

  if(!missing(groups)) groups <- eval(substitute(groups),data)
  if(!missing(subset)) subset <- eval(substitute(subset),data)

  ## Note: c(list(something), NULL) = list(something)
  ## The following was c(list(formula=formula,...,panel=panel),if()c(),...)
  ## 28aug02
  do.call("xyplot", c(list(formula=formula, data=data,
                           prepanel=prepanel, panel=panel),
                      if(length(ylab))list(ylab=ylab),
                      if(length(ylim))list(ylim=ylim),
                      if(length(xlab))list(xlab=xlab),
                      if(length(scales))list(scales=scales),
                      if(length(minor.ticks))list(minor.ticks=minor.ticks),
                      if(!missing(groups))list(groups=groups),
                      if(!missing(subset))list(subset=subset),
                      list(...)))
} else function(formula, data = sys.parent(1), 
                groups = NULL, 
                prepanel=prepanel.xYplot, panel='panel.xYplot',
                scales=NULL, ...,
                xlab=NULL, ylab=NULL,
                subset=TRUE, minor.ticks=NULL) {

  subset <- eval(substitute(subset), data)
  yvname <- deparse(formula[[2]])
  if(!length(ylab)) ylab <- label(eval(formula[[2]],data),
                                  units=TRUE, plot=TRUE, default=yvname)
#    ylab <- attr(eval(formula[[2]], data), 'label')  26sep02
#    if(!length(ylab)) ylab <- yvname
#  }
                
  xv <- formula[[3]]  ## 8Dec00
  if(length(xv)>1 && as.character(xv[[1]])=='|') 
    xv <- xv[[2]]  # ignore conditioning var
  xvname <- deparse(xv)
  xv <- eval(xv, data)
  if(!length(xlab)) xlab <- label(xv, units=TRUE, plot=TRUE, default=xvname)
#    xlab <- attr(xv, 'label') 26sep02
#    if(!length(xlab)) xlab <- xvname
#  }

  if(!length(scales$x)) {
    if(length(maj <- attr(xv,'scales.major'))) scales$x <- maj
  }
  if(!length(minor.ticks)) {
    if(length(minor <- attr(xv,'scales.minor'))) minor.ticks <- minor
  }
  
  setup.2d.trellis(formula, data = data,
				   prepanel=prepanel, panel=panel,
				   groups = eval(substitute(groups),  data), ...,
				   xlab=xlab, ylab=ylab,
                   subset = subset, scales=scales, minor.ticks=minor.ticks)
}

## Only change from default is replacement of x with oldUnclass(x)
if(!.R.)
  shingle <- function(x, intervals = sort(unique(oldUnclass(x)))) {
    if(is.vector(intervals))
      intervals <- cbind(intervals, intervals)
    dimnames(intervals) <- NULL
    attr(x, 'intervals') <- intervals
    class(x) <- 'shingle'   ## 6Aug00 to be like 5.x shingle
    x
  }

prepanel.Dotplot <- function(x, y, ...) {
  xlim <- range(x, attr(x,'other'), na.rm=TRUE)
  ylim <- range(as.numeric(y), na.rm=TRUE)  ## as.numeric 25nov02
  list(xlim=xlim, ylim=ylim) #, dx=diff(xlim), dy=diff(ylim))
}

 panel.Dotplot <- function(x, y, groups = NULL,
                           pch  = dot.symbol$pch, 
                           col  = dot.symbol$col, cex = dot.symbol$cex, 
                           font = dot.symbol$font, abline, ...){
   gfun <- ordGridFun(.R.) ## see Misc.s
   segmnts <- gfun$segments
   y <- as.numeric(y)      ## 7dec02

   gp <- length(groups)
   dot.symbol <- trellis.par.get(if(gp)'superpose.symbol' else 'dot.symbol')
   dot.line   <- trellis.par.get('dot.line')
   plot.line  <- trellis.par.get(if(gp)'superpose.line' else 'plot.line')

   gfun$abline(h = unique(y), lwd=dot.line$lwd, lty=dot.line$lty, 
               col=dot.line$col)
   if(!missing(abline))
     do.call("panel.abline", abline)

   other <- attr(x,'other')
   x <- oldUnclass(x)
   attr(x,'other') <- NULL
   if(length(other)) {
     nc <- ncol(other)
     segmnts(other[,1], y, other[,nc], y, lwd=plot.line$lwd[1],
              lty=plot.line$lty[1], col=plot.line$col[1])
     if(nc==4) {
       segmnts(other[,2], y, other[,3], y, lwd=2*plot.line$lwd[1],
                lty=plot.line$lty[1], col=plot.line$col[1])
       gfun$points(other[,2], y, pch=3, cex=cex, col=col, font=font)
       gfun$points(other[,3], y, pch=3, cex=cex, col=col, font=font)
     }
     ## as.numeric( ) 1 and 6 lines below 23Apr02
     if(gp) panel.superpose(x, y, groups=as.numeric(groups), pch=pch,
                            col=col, cex=cex, font=font, ...) else
     gfun$points(x, y, pch=pch[1], cex=cex, col=col, font=font)
   } else {
     if(gp) 
       panel.superpose(x, y, groups=as.numeric(groups),
                       pch=pch, col=col, cex=cex,
                       font=font, ...) else
     panel.dotplot(x, y, pch=pch, col=col, cex=cex, font=font, ...)
   }
 if(gp) {
     if(.R.) Key <- function(x=0, y=1, lev, cex, col, font, pch, ...) {
       oldpar <- par(usr=c(0,1,0,1),xpd=NA)
       on.exit(par(oldpar))
       if(is.list(x)) { y <- x[[2]]; x <- x[[1]] }
       ## Even though par('usr') shows 0,1,0,1 after lattice draws
       ## its plot, it still needs resetting
       if(!length(x)) x <- 0
       if(!length(y)) y <- 1  ## because of formals()
       rlegend(x, y, legend=lev, cex=cex, col=col, pch=pch)
       invisible()
     } else Key <- function(x=NULL, y=NULL, lev, cex, col, font, pch) { #, ...)
       if(length(x)) {
         if(is.list(x)) {y <- x$y; x <- x$x}
         key(x=x, y=y, text=list(lev, col=col), 
             points=list(cex=cex,col=col,font=font,pch=pch),
             transparent=TRUE)  #, ...)
       } else key(text=list(lev, col=col), 
                  points=list(cex=cex,col=col,font=font,pch=pch),
                  transparent=TRUE)  #, ...)
       invisible()
     }
     lev <- levels(as.factor(groups))
     ng <- length(lev)
     formals(Key) <- list(x=NULL,y=NULL,lev=lev,
                          cex=cex[1:ng], col=col[1:ng],
                          font=font[1:ng], pch=pch[1:ng])   #,...=NULL)
     storeTemp(Key)
   }
 }

 Dotplot <-
  if(.R.) function (formula, data=sys.frame(sys.parent()),
                    groups, subset,
                    xlab=NULL, ylab=NULL, ylim=NULL,
                    panel=panel.Dotplot, prepanel=prepanel.Dotplot,
                    scales=NULL, ...) {

    require('grid')
  require('lattice')
  yvname <- as.character(formula[2])  # tried deparse
  yv <- eval(parse(text=yvname), data)
  if(!length(ylab)) ylab <- label(yv, units=TRUE, plot=TRUE,
                                  default=yvname, grid=TRUE)
#    ylab <- attr(yv, 'label') 26sep02
#    if(!length(ylab)) ylab <- yvname
#  }
  if(!length(ylim)) {
    yother <- attr(yv,'other')
    if(length(yother)) ylim <- range(yv, yother, na.rm=TRUE)
  }
  if(is.character(yv)) yv <- factor(yv)
  if(!length(scales) && is.factor(yv))
    scales <- list(y=list(at=1:length(levels(yv)),labels=levels(yv)))
  
  xvname <- formula[[3]]
  if(length(xvname)>1 && as.character(xvname[[1]])=='|') 
    xvname <- xvname[[2]]  # ignore conditioning var
  xv <- eval(xvname, data)
  if(!length(xlab)) xlab <- label(xv, units=TRUE, plot=TRUE,
                                  default=as.character(xvname), grid=TRUE)
#    xlab <- attr(xv, 'label')  26sep02
#    if(!length(xlab)) xlab <- as.character(xvname)
#  }

  if(!missing(groups)) groups <- eval(substitute(groups),data)
  if(!missing(subset)) subset <- eval(substitute(subset),data)

  dul <- options(drop.unused.levels=FALSE)   ## 25nov02, for empty cells
  on.exit(options(dul))                      ## across some panels
  
  do.call("xyplot", c(list(formula=formula, data=data,
                           prepanel=prepanel, panel=panel),
                      if(length(ylab))list(ylab=ylab),  ## was c(ylab=)
                      if(length(ylim))list(ylim=ylim),  ## 28aug02
                      if(length(xlab))list(xlab=xlab),
                      if(!missing(groups))list(groups=groups),
                      if(!missing(subset))list(subset=subset),
                      if(length(scales))list(scales=scales),
                       list(...)))
} else function(formula, data = sys.parent(1), 
                prepanel=prepanel.Dotplot, panel = 'panel.Dotplot', 
                xlab = NULL, scales = NULL, ylim = NULL, groups = NULL, 
                ..., subset = TRUE) {
	sub.formula <- substitute(formula)
	formula <- eval(sub.formula, data)
	if(missing(xlab)) {
	  xv <- formula[[3]]
	  if(length(xv)>1 && as.character(xv[[1]])=='|') 
		xv <- xv[[2]]  # ignore conditioning var
#	  xlab <- attr(eval(xv, data), 'label') 26sep02
      xlab <- label(eval(xv,data), units=TRUE, plot=TRUE,
                    default=if(is.numeric(formula))
                     deparse(sub.formula) else '') 
	}
#	if(is.null(xlab) && is.numeric(formula))  26sep02
#		xlab <- deparse(sub.formula)
	subset <- eval(substitute(subset), data)
	groups <- eval(substitute(groups), data)

    dul <- options(drop.unused.levels=FALSE)   ## 25nov02, for empty cells
    on.exit(options(dul))

	data <- setup.1d.trellis(formula, data = data, panel=panel,
							 prepanel = prepanel, 
							 xlab = xlab, 
							 groups = groups, ..., subset = subset)
	if(!is.null(scales))
		data$scales <- add.scale.trellis(scales, data$scales)
	if(is.null(scale$y$limits) && is.null(ylim))
		data$scales$y$limits <- data$ylim + c(-0.75, 0.75)
	data
}


setTrellis <- function(strip.blank=TRUE, lty.dot.line=2, lwd.dot.line=1) {
  if(strip.blank) trellis.strip.blank()   # in Hmisc Misc.s
  dot.line <- trellis.par.get('dot.line')
  dot.line$lwd <- lwd.dot.line
  dot.line$lty <- lty.dot.line
  trellis.par.set('dot.line',dot.line)
  invisible()
}

numericScale <- function(x, label=NULL, skip.weekends= FALSE, ...) {
  td <- inherits(x,'timeDate')
  if(td) {
    u <- axis.time(range(x,na.rm=TRUE),
                   skip.weekends=skip.weekends, ...)$grid
    major  <- list(at=as.numeric(u$major.grid$x),
                   labels=format(u$major.grid$x))
    minor  <- list(at=as.numeric(u$minor$x),
                   labels=format(u$minor$x))
  }
  xn <- as.numeric(x)

  attr(xn,'label') <- if(length(label)) label else
    deparse(substitute(x))

  if(td) {
    attr(xn,'scales.major') <- major
    attr(xn,'scales.minor') <- minor
  }
  xn
}

## See proc.scale.trellis, render.trellis, axis.trellis for details of
## how scale is used