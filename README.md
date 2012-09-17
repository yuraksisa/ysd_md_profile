YSD_MD_PROFILE
==============

<p>Profiles, groups and access control management</p>

<p>The API is defined by the following classes:</p>

<ul>
  <li>Users::Profile</li>
  <li>Users::UserGroup</li>
  <li>Users::ResourceAccessControlDataMapper</li>
  <li>Users::ResourceAccessControlPersistence</li>
</ul>

<h2>Users::Profile</h2>

<p>They represent the user accounts</p>

<h2>Users::UserGroup</h2>

<p>They represent the user groups. An user can belong to a some user groups, and they will determinate which actions 
can the user do or which documents can the user access</p>

<h2>Users::ResourceAccessControl</h2>

<ul>
  <li>permission_owner</li>
  <li>permission_group</li>
  <li>permission_modifier_owner</li>
  <li>permission_modifier_group</li>
  <li>permission_modifier_all</li>
</ul>

<h3>Users::ResourceAccessControlDataMapper</li>

<p>It's a module that can be included in a DataMapper resource to control who can access to the instances. It will store the owners of the resource and updates any query to be sure that only the users which permission can access the resource.</p>

<h3>Users::ResourceAccessControlPersistence</li>

<p>It's a module that can be included in a Persistence resource to control who can access to the instances. It will store the owners of the resource and updates any query to be sure that only the users which permission can access the resource.</p>

