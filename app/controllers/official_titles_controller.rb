#
#= OfficialTitlesController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class OfficialTitlesController < ApplicationController
  layout('base')

  before_action(:check_login)

  #=== show
  #
  #Shows OfficialTitle information.
  #
  def show
    Log.add_info(request, params.inspect)

    @group_id = params[:group_id]
    official_title_id = params[:id]
    SqlHelper.validate_token([@group_id, official_title_id])

    unless official_title_id.blank?
      @official_title = OfficialTitle.find(official_title_id)
    end

    render(:layout => (!request.xhr?))
  end

  #=== edit
  #
  #Shows form to edit OfficialTitle.
  #
  def edit
    Log.add_info(request, params.inspect)

    @group_id = params[:group_id]
    official_title_id = params[:id]
    SqlHelper.validate_token([@group_id, official_title_id])

    unless official_title_id.blank?
      @official_title = OfficialTitle.find(official_title_id)
    end

    render(:partial => 'ajax_official_title_form', :layout => (!request.xhr?))
  end

  #=== update
  #
  #Updates OfficialTitle.
  #
  def update
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @group_id = params[:group_id]
    official_title_id = params[:id]
    SqlHelper.validate_token([@group_id, official_title_id])

    if official_title_id.blank?
      @official_title = OfficialTitle.new(OfficialTitle.permit_base(params.require(:official_title)))
      @official_title.group_id = @group_id

      @official_title.save!
    else
      @official_title = OfficialTitle.find(official_title_id)
      @official_title.update_attributes(OfficialTitle.permit_base(params.require(:official_title)))
    end

    @official_titles = OfficialTitle.get_for(@group_id, false, true)

    render(:partial => 'groups/ajax_group_official_titles', :layout => false)
  end

  #=== destroy
  #
  #Destroys the specified OfficialTitle.
  #
  def destroy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    begin
      OfficialTitle.destroy(params[:id])
    rescue => evar
      Log.add_error(nil, evar)
    end

    @group_id = params[:group_id]
    SqlHelper.validate_token([@group_id])

    if @group_id.blank?
      @group_id = TreeElement::ROOT_ID.to_s
    end

    render(:partial => 'groups/ajax_group_official_titles', :layout => false)
  end

  #=== update_order
  #
  #Updates OfficialTitles' order.
  #
  def update_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    order_arr = params[:official_titles_order]

    @group_id = params[:group_id]
    SqlHelper.validate_token([@group_id])

    parent_titles = OfficialTitle.get_for(Group.find(@group_id).parent_id, true, true)
    order_offset = parent_titles.length

    @official_titles = OfficialTitle.get_for(@group_id, false, true)

    @official_titles.each do |official_title|
      official_title.update_attribute(:xorder, order_offset + order_arr.index(official_title.id.to_s) + 1)
    end

    render(:plain => '')
  end
end
