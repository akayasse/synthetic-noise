pro add_noise_nedl
 start_time = systime(/seconds)

;;;;;;;;;;;;INPUTS;;;;;;;;;;;;;;

; original image must have attribute bands
img_folder = 'F:\Sensitivity_Analysis_20141212\make_image_out\sensitivity_analysis\'
image_name ='sensitivity_analysis_4_alb50_ch4_25_102_by_100'
NEdL_coef_C_file = img_folder + 'C_fit_params.txt'
img_orig = img_folder + image_name

out_folder = 'F:\Sensitivity_Analysis_20141212\add_noise_out\sensitivity_analysis\'
out_name = image_name+'_noise_nedl'
out_noise_name = 'noise_only'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; open the image file

 ENVI_OPEN_FILE, img_orig, R_FID = my_fid
 
 ENVI_FILE_QUERY, my_fid, BNAMES = BNAMES, NB = NB, NL = NL, NS = NS, WL = WL, dims = dims, data_type = dt, map_info = map_info
 
 ; read in NEdL scaling factors
 coefs_temp = fltarr(5,224)
 str_temp = strarr(1)
 get_lun, u
 openr, u, NEdL_coef_C_file
 readf, u, str_temp
 readf, u, coefs_temp
 close, u
 free_lun, u

 ; get rid of first column (wavelength) and last column (RMSE) from input array
 coefs = coefs_temp(1:3,0:223)
 
 ; make empty arrays
 rad = make_array(1,1,1)
 noise = make_array(1,1,1)
 img_start = make_array(NS,NL,NB)
 img_noise = make_array(NS,NL,NB)
 random_noise = make_array(NS,NL,NB)
 
 for z=0,NB-1 do begin
 img_start[*,*,z] = ENVI_GET_DATA( fid = my_fid, dims = dims, pos = z)
 endfor
 
 for s = 0,NS-1 do begin
  for l = 0,NL-1 do begin
    for b = 0,NB-1 do begin
    
    rad = img_start[s,l,b]
    nedl = coefs(0,b)*sqrt(coefs(1,b)+rad)+coefs(2,b)
    noise = RANDOMU(seed,1)*nedl 
    noise_rad = FLOAT(noise + rad)

    img_noise[s,l,b] = noise_rad
    random_noise[s,l,b] = noise
   endfor
  endfor 
 endfor

;creat the image with the noise 
 out_img = out_folder+out_name

 openw,2,out_img
 writeu, 2, img_noise
 close,2
 
 ;set up and write the envi header for output image
 ENVI_SETUP_HEAD, fname= out_img+'.hdr' $
  ,nb=nb, nl= nl, ns = ns, data_type= dt, interleave=0,$
    bnames=BNAMES, wl=WL, map_info = map_info,/write

;creat an image that is just the added noise component     
  out_noise = out_folder+out_noise_name

  openw,2,out_noise
  writeu, 2, random_noise
  close,2

  ;set up and write the envi header for output image
  ENVI_SETUP_HEAD, fname= out_noise+'.hdr' $
    ,nb=nb, nl= nl, ns = ns, data_type= dt, interleave=0,$
    bnames=BNAMES, wl=WL, map_info = map_info,/write
 
  
print, 'DONE'
print, "Elapsed time = ", (systime(/seconds) - start_time)/60, " minutes"
end 

